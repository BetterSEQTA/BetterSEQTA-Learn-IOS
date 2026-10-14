import Domain
import Foundation

enum LearnCourseThemesParser {
    static func parseThemeCatalog(_ payload: Any?) -> [CourseDocumentTheme] {
        let rows: [JSONObject]
        if let array = payload as? [JSONObject] {
            rows = array
        } else if let array = payload as? [Any] {
            rows = array.compactMap { $0 as? JSONObject }
        } else {
            return []
        }
        guard let first = rows.first,
              JSONObjectHelpers.string(first, keys: "accentColour", "accentColor") != nil else {
            return []
        }
        return rows.compactMap(parseThemeRow)
    }

    private static func parseThemeRow(_ row: JSONObject) -> CourseDocumentTheme? {
        guard let uuid = JSONObjectHelpers.string(row, keys: "uuid") else { return nil }
        let name = JSONObjectHelpers.string(row, keys: "name") ?? "Theme"
        let userfile = row["userfile"] as? JSONObject
        let headerUUID = JSONObjectHelpers.string(userfile ?? [:], keys: "uuid")
        return CourseDocumentTheme(
            id: uuid,
            name: name,
            accentColour: JSONObjectHelpers.string(row, keys: "accentColour", "accentColor") ?? "#25b3fd",
            accentContrastColour: JSONObjectHelpers.string(row, keys: "accentContrastColour", "accentContrastColor") ?? "#fff",
            textColour: JSONObjectHelpers.string(row, keys: "textColour", "textColor") ?? "#000",
            documentBackground: JSONObjectHelpers.string(row, keys: "documentBackground") ?? "#f8f8f8",
            cardBackground: JSONObjectHelpers.string(row, keys: "cardBackground") ?? "#f8f8f8",
            moduleBackground: JSONObjectHelpers.string(row, keys: "moduleBackground") ?? "#fff",
            cardBorderColour: JSONObjectHelpers.string(row, keys: "cardBorderColour", "cardBorderColor") ?? "#eee",
            fontFamily: JSONObjectHelpers.string(row, keys: "fontFamily") ?? "",
            fontSize: JSONObjectHelpers.string(row, keys: "fontSize") ?? "11pt",
            applyImage: JSONObjectHelpers.bool(row, key: "applyImage") ?? false,
            headerImageUUID: headerUUID
        )
    }
}
