import Domain
import Foundation

/// Ports DesQTA `courseService.parseDocument`, `moduleUtils`, and `renderDraftJSText`.
enum LearnCourseDocumentParser {
    private enum ModuleType {
        static let legacyEditor = "0d49d130-c197-421d-a56a-d1ba0a67cfc0"
        static let previewLexical = "f388e4f9-b350-4ee8-964b-2618ea4a037a"
        static let columnLayout = "c082b45f-abf5-41fa-9c15-74233ab52c91"
        static let link = "e3f1b225-d159-4a7f-bc84-2fddf05ed6d6"
        static let formula = "b30fef7f-528f-4c0c-bfb4-0cc78e77767a"
    }

    static func parseCoursePayload(_ payload: Any?) -> CourseContent? {
        guard let object = payload as? JSONObject else { return nil }
        let hasCourseBody = object["document"] != nil
            || object["w"] != nil
            || object["cf"] != nil
            || JSONObjectHelpers.string(object, keys: "o") != nil
            || JSONObjectHelpers.string(object, keys: "t", "title") != nil
        guard hasCourseBody else { return nil }

        let title = JSONObjectHelpers.string(object, keys: "t", "title") ?? "Course"
        let code = JSONObjectHelpers.string(object, keys: "c", "code") ?? ""
        let headerImageUUID = JSONObjectHelpers.string(object, keys: "im", "image")

        var documentParseError = false
        var overviewBlocks: [CourseRenderedBlock] = []
        var themeReference: String?
        if let documentInput = normalizedDocumentInput(object["document"]) {
            let parsed = parseDocumentModules(documentInput)
            documentParseError = parsed.parseError
            overviewBlocks = parsed.blocks
            themeReference = parsed.themeReference
        }

        if let overviewHTML = JSONObjectHelpers.string(object, keys: "o")?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !overviewHTML.isEmpty {
            overviewBlocks.insert(.html(overviewHTML), at: 0)
        }

        let courseFiles = parseCourseFiles(object["cf"])
        let lessons = parseWeeklyLessons(object["w"])

        return CourseContent(
            code: code,
            title: title,
            overviewBlocks: overviewBlocks,
            lessons: lessons,
            courseFiles: courseFiles,
            documentParseError: documentParseError,
            themeReference: themeReference,
            headerImageUUID: headerImageUUID
        )
    }

    /// JSON string, raw HTML, or already-parsed document object (some SEQTA responses).
    private static func normalizedDocumentInput(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let object = value as? JSONObject {
            if let contents = JSONObjectHelpers.string(object, keys: "contents") {
                return contents
            }
            if let data = try? JSONSerialization.data(withJSONObject: object),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
        }
        return nil
    }

    // MARK: - Document modules

    private struct ParsedDocumentModules {
        var blocks: [CourseRenderedBlock]
        var parseError: Bool
        var themeReference: String?
    }

    private static func parseDocumentModules(_ documentString: String) -> ParsedDocumentModules {
        let trimmed = documentString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("<") {
            return ParsedDocumentModules(blocks: [.html(trimmed)], parseError: false, themeReference: nil)
        }
        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? JSONObject else {
            return ParsedDocumentModules(blocks: [], parseError: true, themeReference: nil)
        }
        let root = (json["document"] as? JSONObject) ?? json
        let themeReference = JSONObjectHelpers.string(root, keys: "theme")
        guard let rawModules = root["modules"] as? [JSONObject] else {
            return ParsedDocumentModules(blocks: [], parseError: false, themeReference: themeReference)
        }
        let modules = sortModules(rawModules)
        let columnParents = Set(
            modules.filter { JSONObjectHelpers.string($0, keys: "type") == ModuleType.columnLayout }.compactMap {
                JSONObjectHelpers.string($0, keys: "uuid")
            }
        )
        let filtered = modules.filter { module in
            guard let parent = JSONObjectHelpers.string(module, keys: "parentModule") else { return true }
            return !columnParents.contains(parent)
        }
        let blocks = renderModuleList(filtered, allModules: modules)
        return ParsedDocumentModules(blocks: blocks, parseError: false, themeReference: themeReference)
    }

    private static func parseLessonDocument(_ contents: String?) -> [CourseRenderedBlock] {
        guard let contents, !contents.isEmpty else { return [] }
        return parseDocumentModules(contents).blocks
    }

    private static func parseInlineLessonHTML(_ html: String?) -> [CourseRenderedBlock] {
        guard let html else { return [] }
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return [.html(trimmed)]
    }

    // MARK: - Weekly lessons

    private static func parseWeeklyLessons(_ value: Any?) -> [CourseLessonItem] {
        guard let weeks = value as? [Any] else { return [] }
        var items: [CourseLessonItem] = []
        for (weekIndex, week) in weeks.enumerated() {
            guard let days = week as? [Any] else { continue }
            for (dayIndex, day) in days.enumerated() {
                guard let object = day as? JSONObject else { continue }
                let title = JSONObjectHelpers.string(object, keys: "t", "topic", "title") ?? "Lesson"
                let homework = JSONObjectHelpers.string(object, keys: "h", "o")
                var blocks: [CourseRenderedBlock] = []
                if let doc = object["document"] as? JSONObject {
                    blocks = parseLessonDocument(JSONObjectHelpers.string(doc, keys: "contents"))
                } else if let documentString = normalizedDocumentInput(object["document"]) {
                    blocks = parseLessonDocument(documentString)
                } else if let contents = JSONObjectHelpers.string(object, keys: "contents") {
                    blocks = parseLessonDocument(contents)
                }
                if blocks.isEmpty {
                    blocks = parseInlineLessonHTML(JSONObjectHelpers.string(object, keys: "l"))
                }
                let resources = parseLessonResources(object["r"])
                let hasBody = !blocks.isEmpty
                    || !(homework?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                    || !resources.isEmpty
                guard hasBody || title != "Lesson" else { continue }
                let id = "\(weekIndex)-\(dayIndex)-\(title)"
                items.append(
                    CourseLessonItem(
                        id: id,
                        weekIndex: weekIndex,
                        dayIndex: dayIndex,
                        title: title,
                        homework: homework,
                        resources: resources,
                        blocks: blocks
                    )
                )
            }
        }
        return items
    }

    private static func parseLessonResources(_ value: Any?) -> [CourseResourceFile] {
        guard let rows = value as? [JSONObject] else { return [] }
        return rows.compactMap { parseResourceRow($0, defaultTitle: "Resource") }
    }

    private static func parseCourseFiles(_ value: Any?) -> [CourseResourceFile] {
        guard let rows = value as? [JSONObject] else { return [] }
        return rows.compactMap { parseResourceRow($0, defaultTitle: "File") }
    }

    private static func parseResourceRow(_ row: JSONObject, defaultTitle: String) -> CourseResourceFile? {
        let uuid = JSONObjectHelpers.string(row, keys: "uuid") ?? ""
        guard !uuid.isEmpty else { return nil }
        let id = JSONObjectHelpers.int(row, keys: "id", "userfile", "i") ?? abs(uuid.hashValue)
        let filename = JSONObjectHelpers.string(row, keys: "filename", "name", "t") ?? defaultTitle
        let mimetype = JSONObjectHelpers.string(row, keys: "mimetype") ?? "application/octet-stream"
        let size = JSONObjectHelpers.string(row, keys: "size") ?? ""
        return CourseResourceFile(
            id: id,
            filename: filename,
            sizeLabel: formatFileSize(size),
            uuid: uuid,
            mimetype: mimetype
        )
    }

    // MARK: - Module rendering

    private static func renderModuleList(_ modules: [JSONObject], allModules: [JSONObject]) -> [CourseRenderedBlock] {
        var blocks: [CourseRenderedBlock] = []
        for module in modules {
            blocks.append(contentsOf: renderModule(module, allModules: allModules))
        }
        return blocks
    }

    private static func renderModule(_ module: JSONObject, allModules: [JSONObject]) -> [CourseRenderedBlock] {
        let type = JSONObjectHelpers.string(module, keys: "type") ?? ""
        let content = module["content"] as? JSONObject

        if isFormulaModule(type: type, content: content) {
            let formula = JSONObjectHelpers.string(content ?? [:], keys: "formula") ?? ""
            return formula.isEmpty ? [] : [.formula(formula)]
        }

        if isPollModule(type: type, content: content) {
            let proposition = JSONObjectHelpers.string(content ?? [:], keys: "proposition") ?? "Poll"
            let options = (content?["options"] as? [Any])?.compactMap { $0 as? String } ?? []
            return [.poll(proposition: proposition, options: options)]
        }

        if isTitleModule(content) {
            return [.title((content?["value"] as? String) ?? "")]
        }

        if let content, let html = content["html"] as? String,
           content["editor"] as? String == "lexical" || type == ModuleType.previewLexical
            || content["displayMode"] != nil {
            return htmlBlock(html)
        }

        if type == ModuleType.columnLayout,
           let content, let layout = content["AdvanceLayout"] as? JSONObject {
            return renderColumnLayout(layout, allModules: allModules)
        }

        if type == ModuleType.legacyEditor,
           let content, let html = content["content"] as? String {
            if html.lowercased().contains("<table") {
                return [.html(wrapTable(html))]
            }
            return htmlBlock(html)
        }

        if let content, let draft = content["content"] as? JSONObject,
           let blocks = draft["blocks"] as? [JSONObject] {
            let entityMap = (draft["entityMap"] as? JSONObject) ?? [:]
            let html = renderDraftJS(blocks: blocks, entityMap: entityMap)
            return html.isEmpty ? [] : [.html(html)]
        }

        if let content, let resources = content["value"] as? JSONObject,
           let list = resources["resources"] as? [JSONObject] {
            let files = list.compactMap { row -> CourseResourceFile? in
                let selected = JSONObjectHelpers.bool(row, key: "selected") ?? true
                guard selected else { return nil }
                return parseResourceRow(row, defaultTitle: "Resource")
            }
            return files.isEmpty ? [] : [.resources(files)]
        }

        if let content {
            let url = JSONObjectHelpers.string(content, keys: "url", "embedLink") ?? ""
            if !url.isEmpty, URL(string: url) != nil {
                return [.link(url)]
            }
        }

        return []
    }

    private static func renderColumnLayout(_ layout: JSONObject, allModules: [JSONObject]) -> [CourseRenderedBlock] {
        let columns = ["col1", "col2", "col3"]
        var blocks: [CourseRenderedBlock] = []
        for column in columns {
            guard let uuids = layout[column] as? [String] else { continue }
            for uuid in uuids {
                guard let module = allModules.first(where: { JSONObjectHelpers.string($0, keys: "uuid") == uuid }) else {
                    continue
                }
                blocks.append(contentsOf: renderModule(module, allModules: allModules))
            }
        }
        return blocks
    }

    private static func isTitleModule(_ content: JSONObject?) -> Bool {
        guard let content else { return false }
        guard let title = content["value"] as? String, !title.isEmpty else { return false }
        if content["content"] != nil { return false }
        if content["html"] != nil { return false }
        if content["AdvanceLayout"] != nil { return false }
        if content["formula"] != nil { return false }
        if content["proposition"] != nil { return false }
        if content["value"] is [String: Any] { return false }
        let url = JSONObjectHelpers.string(content, keys: "url", "embedLink") ?? ""
        if !url.isEmpty { return false }
        return true
    }

    private static func isFormulaModule(type: String, content: JSONObject?) -> Bool {
        guard type == ModuleType.link, let content else { return false }
        return JSONObjectHelpers.string(content, keys: "formula") != nil
    }

    private static func isPollModule(type: String, content: JSONObject?) -> Bool {
        guard type == ModuleType.formula, let content else { return false }
        return content["proposition"] != nil && content["options"] != nil
    }

    private static func htmlBlock(_ html: String) -> [CourseRenderedBlock] {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? [] : [.html(trimmed)]
    }

    private static func wrapTable(_ html: String) -> String {
        """
        <div class="course-table-wrap">\(html)</div>
        """
    }

    // MARK: - DraftJS

    private static func renderDraftJS(blocks: [JSONObject], entityMap: JSONObject) -> String {
        var html = ""
        var listStack: [(type: String, depth: Int)] = []

        func closeLists(to depth: Int) {
            while let top = listStack.last, top.depth > depth {
                listStack.removeLast()
                html += top.type == "ul" ? "</li></ul>" : "</li></ol>"
            }
        }

        func closeAllLists() {
            while let top = listStack.popLast() {
                html += top.type == "ul" ? "</li></ul>" : "</li></ol>"
            }
        }

        for block in blocks {
            let text = applyInlineStyles(
                JSONObjectHelpers.string(block, keys: "text") ?? "",
                block: block,
                entityMap: entityMap
            )
            let depth = JSONObjectHelpers.int(block, keys: "depth") ?? 0
            let blockType = JSONObjectHelpers.string(block, keys: "type") ?? "unstyled"

            if blockType == "unordered-list-item" {
                closeLists(to: depth)
                if listStack.last?.type != "ul" || listStack.last?.depth != depth {
                    closeLists(to: depth - 1)
                    html += "<ul>"
                    listStack.append((type: "ul", depth: depth))
                } else {
                    html += "</li>"
                }
                html += "<li>\(text.isEmpty ? "&nbsp;" : text)"
                continue
            }

            if blockType == "ordered-list-item" {
                closeLists(to: depth)
                if listStack.last?.type != "ol" || listStack.last?.depth != depth {
                    closeLists(to: depth - 1)
                    html += "<ol>"
                    listStack.append((type: "ol", depth: depth))
                } else {
                    html += "</li>"
                }
                html += "<li>\(text.isEmpty ? "&nbsp;" : text)"
                continue
            }

            closeAllLists()

            switch blockType {
            case "header-one":
                html += "<h1>\(text)</h1>"
            case "header-two":
                html += "<h2>\(text)</h2>"
            case "header-three":
                html += "<h3>\(text)</h3>"
            default:
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    html += "<p>\(text)</p>"
                }
            }
        }
        closeAllLists()
        return html
    }

    private static func applyInlineStyles(
        _ text: String,
        block: JSONObject,
        entityMap: JSONObject
    ) -> String {
        var output = text
        let styleRanges = (block["inlineStyleRanges"] as? [JSONObject]) ?? []
        let entityRanges = (block["entityRanges"] as? [JSONObject]) ?? []

        struct RangeSpec {
            let offset: Int
            let length: Int
            let kind: String
            let style: String?
            let entityKey: Int?
        }

        var specs: [RangeSpec] = []
        for range in styleRanges {
            guard let offset = JSONObjectHelpers.int(range, keys: "offset"),
                  let length = JSONObjectHelpers.int(range, keys: "length"),
                  let style = JSONObjectHelpers.string(range, keys: "style") else { continue }
            specs.append(RangeSpec(offset: offset, length: length, kind: "style", style: style, entityKey: nil))
        }
        for range in entityRanges {
            guard let offset = JSONObjectHelpers.int(range, keys: "offset"),
                  let length = JSONObjectHelpers.int(range, keys: "length"),
                  let key = JSONObjectHelpers.int(range, keys: "key") else { continue }
            specs.append(RangeSpec(offset: offset, length: length, kind: "entity", style: nil, entityKey: key))
        }

        let grouped = Dictionary(grouping: specs) { "\($0.offset)-\($0.length)" }
        let keys = grouped.keys.sorted { lhs, rhs in
            Int(lhs.split(separator: "-").first ?? "0")! > Int(rhs.split(separator: "-").first ?? "0")!
        }

        for key in keys {
            guard let ranges = grouped[key] else { continue }
            let parts = key.split(separator: "-")
            guard parts.count == 2, let offset = Int(parts[0]), let length = Int(parts[1]) else { continue }
            let start = output.index(output.startIndex, offsetBy: min(offset, output.count))
            let end = output.index(start, offsetBy: min(length, output.count - offset), limitedBy: output.endIndex) ?? output.endIndex
            var wrapped = String(output[start ..< end])
            for range in ranges {
                if range.kind == "entity", let entityKey = range.entityKey,
                   let entity = entityMap[String(entityKey)] as? JSONObject,
                   JSONObjectHelpers.string(entity, keys: "type") == "LINK",
                   let data = entity["data"] as? JSONObject {
                    let href = JSONObjectHelpers.string(data, keys: "href", "url") ?? "#"
                    wrapped = "<a href=\"\(href)\">\(wrapped)</a>"
                } else if range.kind == "style", let style = range.style {
                    switch style {
                    case "BOLD": wrapped = "<strong>\(wrapped)</strong>"
                    case "ITALIC": wrapped = "<em>\(wrapped)</em>"
                    case "UNDERLINE": wrapped = "<u>\(wrapped)</u>"
                    case "STRIKETHROUGH": wrapped = "<s>\(wrapped)</s>"
                    case "CODE": wrapped = "<code>\(wrapped)</code>"
                    default: break
                    }
                }
            }
            output.replaceSubrange(start ..< end, with: wrapped)
        }
        return output
    }

    // MARK: - Module ordering

    private static func sortModules(_ modules: [JSONObject]) -> [JSONObject] {
        guard !modules.isEmpty else { return [] }
        let map = Dictionary(uniqueKeysWithValues: modules.compactMap { module -> (String, JSONObject)? in
            guard let uuid = JSONObjectHelpers.string(module, keys: "uuid") else { return nil }
            return (uuid, module)
        })
        guard let first = modules.first(where: { module in
            let prev = JSONObjectHelpers.string(module, keys: "prevModule")
            return prev == nil || map[prev ?? ""] == nil
        }) else {
            return modules
        }

        var ordered: [JSONObject] = []
        var current: JSONObject? = first
        while let module = current, ordered.count < modules.count {
            ordered.append(module)
            let next = JSONObjectHelpers.string(module, keys: "nextModule")
            current = next.flatMap { map[$0] }
        }
        let orderedIDs = Set(ordered.compactMap { JSONObjectHelpers.string($0, keys: "uuid") })
        for module in modules {
            let uuid = JSONObjectHelpers.string(module, keys: "uuid") ?? ""
            if !orderedIDs.contains(uuid) { ordered.append(module) }
        }
        return ordered
    }

    private static func formatFileSize(_ raw: String) -> String {
        guard let bytes = Int(raw) else { return raw }
        let units = ["B", "KB", "MB", "GB"]
        var size = Double(bytes)
        var index = 0
        while size >= 1024, index < units.count - 1 {
            size /= 1024
            index += 1
        }
        return String(format: "%.1f %@", size, units[index])
    }
}
