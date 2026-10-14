import CoreDesign
import Domain
import SwiftUI

struct LearnCourseContentScreen: View {
    let subject: Subject
    let content: CourseContent
    @Bindable var viewModel: LearnCoursesViewModel

    @State private var section: CourseDetailSection = .overview
    @State private var selectedLessonID: String?
    @State private var lessonSearch = ""
    @State private var showLessonBrowser = false
    @State private var expandedWeeks: Set<Int> = []

    private var theme: ResolvedCourseTheme {
        viewModel.resolvedTheme(for: content, subjectCode: subject.code)
    }

    private var accent: Color { theme.accent }

    private var lessonWeekGroups: [CourseLessonWeekGroup] {
        CourseLessonWeekGroup.make(from: content.lessons)
    }

    private var filteredLessonGroups: [CourseLessonWeekGroup] {
        let query = lessonSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return lessonWeekGroups }
        return lessonWeekGroups.compactMap { group in
            let lessons = group.lessons.filter {
                $0.title.lowercased().contains(query)
                    || ($0.homework?.lowercased().contains(query) ?? false)
            }
            guard !lessons.isEmpty else { return nil }
            return CourseLessonWeekGroup(weekIndex: group.weekIndex, lessons: lessons)
        }
    }

    private var usesCompactLessonBrowser: Bool {
        content.lessons.count > 14
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                courseTitleBanner

                if content.documentParseError {
                    parseErrorCard
                }

                if !content.lessons.isEmpty {
                    LearnUnderlineSegmentBar(
                        items: CourseDetailSection.allCases.map { ($0, $0.label) },
                        selection: section,
                        density: .compact,
                        style: .fluid
                    ) { section = $0 }
                }

                switch section {
                case .overview:
                    LearnCourseModuleStack(
                        blocks: content.overviewBlocks,
                        accent: accent,
                        courseFiles: content.courseFiles,
                        headerImageUUID: content.headerImageUUID,
                        downloadingFileUUID: viewModel.downloadingCourseFileUUID,
                        onOpenFile: { file in Task { await viewModel.openCourseFile(file) } }
                    )
                    if !content.courseFiles.isEmpty {
                        courseFilesSection(content.courseFiles)
                    }
                case .lessons:
                    lessonSelectorChrome
                    if let lesson = selectedLesson {
                        lessonDetail(lesson)
                    } else {
                        LearnEmptyState(
                            title: "Select a lesson",
                            message: "Choose a lesson from the list to view its content."
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(theme.pageBackground.opacity(0.35))
        .task { await viewModel.ensureDocumentThemesLoaded() }
        .onAppear {
            if selectedLessonID == nil {
                selectedLessonID = content.lessons.first?.id
            }
            if expandedWeeks.isEmpty, let firstWeek = lessonWeekGroups.first?.weekIndex {
                expandedWeeks.insert(firstWeek)
            }
            ensureWeekExpandedForSelection()
        }
        .onChange(of: selectedLessonID) { _, _ in
            ensureWeekExpandedForSelection()
        }
        .sheet(isPresented: $showLessonBrowser) {
            LearnCourseLessonBrowserSheet(
                groups: lessonWeekGroups,
                selection: $selectedLessonID,
                accent: accent
            )
        }
        .alert(
            "Couldn't open file",
            isPresented: Binding(
                get: { viewModel.courseFileErrorMessage != nil },
                set: { if !$0 { viewModel.clearCourseFileError() } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.clearCourseFileError() }
        } message: {
            Text(viewModel.courseFileErrorMessage ?? "")
        }
    }

    private func ensureWeekExpandedForSelection() {
        guard let selectedLessonID,
              let lesson = content.lessons.first(where: { $0.id == selectedLessonID }) else { return }
        expandedWeeks.insert(lesson.weekIndex)
    }

    private func selectLesson(_ lesson: CourseLessonItem) {
        LearnHaptics.selection()
        withAnimation(LearnMotion.spatialStandardDefault) {
            selectedLessonID = lesson.id
            expandedWeeks.insert(lesson.weekIndex)
        }
    }

    private var courseTitleBanner: some View {
        Text(content.title)
            .font(.title2.weight(.bold))
            .foregroundStyle(theme.accentContrast)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(accent, in: RoundedRectangle(cornerRadius: LearnTheme.cardCornerRadius, style: .continuous))
    }

    private var parseErrorCard: some View {
        LearnGlassCard {
            Text("Some course content could not be parsed. You may still see files and lessons below.")
                .font(.footnote)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
        }
    }

    @ViewBuilder
    private var lessonSelectorChrome: some View {
        VStack(alignment: .leading, spacing: 12) {
            LearnSectionHeader(
                title: "Lessons",
                subtitle: "\(content.lessons.count) published",
                actionLabel: usesCompactLessonBrowser ? "Browse all" : nil,
                onAction: usesCompactLessonBrowser ? { showLessonBrowser = true } : nil
            )

            if usesCompactLessonBrowser {
                if let lesson = selectedLesson {
                    Button {
                        showLessonBrowser = true
                    } label: {
                        LearnCourseLessonRow(lesson: lesson, isSelected: true, accent: accent, showsChevron: true)
                    }
                    .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))
                }
            } else {
                if content.lessons.count > 6 {
                    LearnSearchField(text: $lessonSearch, compact: true)
                        .learnComposeMaterial(cornerRadius: LearnTheme.controlCornerRadius)
                }
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredLessonGroups.enumerated()), id: \.element.id) { index, group in
                            LearnCourseLessonWeekSection(
                                group: group,
                                selection: selectedLessonID,
                                accent: accent,
                                isExpanded: expandedWeeks.contains(group.weekIndex),
                                onToggle: {
                                    if expandedWeeks.contains(group.weekIndex) {
                                        expandedWeeks.remove(group.weekIndex)
                                    } else {
                                        expandedWeeks.insert(group.weekIndex)
                                    }
                                },
                                onSelect: selectLesson
                            )
                            if index < filteredLessonGroups.count - 1 {
                                LearnSeparatorHairline()
                            }
                        }
                        if filteredLessonGroups.isEmpty {
                            Text("No lessons match your search.")
                                .font(.subheadline)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
    }

    private var selectedLesson: CourseLessonItem? {
        guard let selectedLessonID else { return nil }
        return content.lessons.first { $0.id == selectedLessonID }
    }

    private func lessonDetail(_ lesson: CourseLessonItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lesson.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
            if let homework = lesson.homework, !homework.isEmpty {
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Homework & notes")
                            .font(.subheadline.weight(.semibold))
                        if homework.contains("<") {
                            LearnCourseHTMLBody(
                                html: homework,
                                courseFiles: content.courseFiles,
                                headerImageUUID: content.headerImageUUID,
                                onOpenFile: { file in Task { await viewModel.openCourseFile(file) } }
                            )
                        } else {
                            Text(homework)
                                .font(.body)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                                .learnReadableBody()
                        }
                    }
                }
            }
            if !lesson.resources.isEmpty {
                lessonResourcesSection(lesson.resources)
            }
            LearnCourseModuleStack(
                blocks: lesson.blocks,
                accent: accent,
                courseFiles: content.courseFiles + lesson.resources,
                headerImageUUID: content.headerImageUUID,
                downloadingFileUUID: viewModel.downloadingCourseFileUUID,
                onOpenFile: { file in Task { await viewModel.openCourseFile(file) } }
            )
        }
    }

    private func lessonResourcesSection(_ files: [CourseResourceFile]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lesson resources")
                .font(.headline)
                .foregroundStyle(theme.text)
            ForEach(files) { file in
                Button {
                    LearnHaptics.lightImpact()
                    Task { await viewModel.openCourseFile(file) }
                } label: {
                    LearnCourseResourceFileRow(
                        file: file,
                        icon: fileIcon(for: file.mimetype),
                        isLoading: viewModel.downloadingCourseFileUUID == file.uuid
                    )
                }
                .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))
                .disabled(viewModel.downloadingCourseFileUUID != nil)
            }
        }
    }

    private func courseFilesSection(_ files: [CourseResourceFile]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Course files")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(accent.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            ForEach(files) { file in
                Button {
                    LearnHaptics.lightImpact()
                    Task { await viewModel.openCourseFile(file) }
                } label: {
                    LearnCourseResourceFileRow(
                        file: file,
                        icon: fileIcon(for: file.mimetype),
                        isLoading: viewModel.downloadingCourseFileUUID == file.uuid
                    )
                }
                .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))
                .disabled(viewModel.downloadingCourseFileUUID != nil)
            }
        }
    }

    private func fileIcon(for mimetype: String) -> String {
        let type = mimetype.lowercased()
        if type.contains("pdf") { return "📄" }
        if type.contains("image") { return "🖼️" }
        if type.contains("video") { return "🎥" }
        if type.contains("audio") { return "🎵" }
        return "📎"
    }
}

// MARK: - Lesson list

private struct CourseLessonWeekGroup: Identifiable {
    let weekIndex: Int
    let lessons: [CourseLessonItem]

    var id: Int { weekIndex }

    static func make(from lessons: [CourseLessonItem]) -> [CourseLessonWeekGroup] {
        let grouped = Dictionary(grouping: lessons, by: \.weekIndex)
        return grouped.keys.sorted().map { week in
            CourseLessonWeekGroup(
                weekIndex: week,
                lessons: (grouped[week] ?? []).sorted { $0.dayIndex < $1.dayIndex }
            )
        }
    }
}

private struct LearnCourseLessonWeekSection: View {
    let group: CourseLessonWeekGroup
    let selection: String?
    let accent: Color
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSelect: (CourseLessonItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                LearnHaptics.selection()
                withAnimation(LearnMotion.spatialStandardDefault) { onToggle() }
            } label: {
                HStack {
                    Text(group.weekIndex == 0 ? "This week" : "Week \(group.weekIndex + 1)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                    Text("\(group.lessons.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LearnTheme.Colors.groupedFill.opacity(0.5), in: Capsule())
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(group.lessons) { lesson in
                        Button {
                            onSelect(lesson)
                        } label: {
                            LearnCourseLessonRow(
                                lesson: lesson,
                                isSelected: lesson.id == selection,
                                accent: accent,
                                showsChevron: false
                            )
                        }
                        .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))
                        if lesson.id != group.lessons.last?.id {
                            LearnSeparatorHairline()
                                .padding(.leading, 12)
                        }
                    }
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct LearnCourseLessonRow: View {
    let lesson: CourseLessonItem
    let isSelected: Bool
    let accent: Color
    let showsChevron: Bool

    private var hasContent: Bool {
        !lesson.blocks.isEmpty || !(lesson.homework?.isEmpty ?? true)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(hasContent ? accent : LearnTheme.Colors.tertiaryText.opacity(0.35))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                if let homework = lesson.homework, !homework.isEmpty {
                    Text(homework)
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(2)
                } else if !hasContent {
                    Text("No content yet")
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.tertiaryText)
                }
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LearnTheme.Colors.tertiaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? accent.opacity(0.14) : Color.clear)
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(accent.opacity(0.35), lineWidth: 1)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct LearnCourseLessonBrowserSheet: View {
    let groups: [CourseLessonWeekGroup]
    @Binding var selection: String?
    let accent: Color

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filteredGroups: [CourseLessonWeekGroup] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return groups }
        return groups.compactMap { group in
            let lessons = group.lessons.filter { $0.title.lowercased().contains(query) }
            guard !lessons.isEmpty else { return nil }
            return CourseLessonWeekGroup(weekIndex: group.weekIndex, lessons: lessons)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups) { group in
                    Section(group.weekIndex == 0 ? "This week" : "Week \(group.weekIndex + 1)") {
                        ForEach(group.lessons) { lesson in
                            Button {
                                selection = lesson.id
                                LearnHaptics.selection()
                                dismiss()
                            } label: {
                                LearnCourseLessonRow(
                                    lesson: lesson,
                                    isSelected: lesson.id == selection,
                                    accent: accent,
                                    showsChevron: false
                                )
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background { LearnScreenBackground() }
            .searchable(text: $search, prompt: "Search lessons")
            .navigationTitle("All lessons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .learnLiquidGlassSheetBackground()
    }
}

private enum CourseDetailSection: CaseIterable, Hashable {
    case overview
    case lessons

    var label: String {
        switch self {
        case .overview: "Overview"
        case .lessons: "Lessons"
        }
    }
}

private struct LearnCourseResourceFileRow: View {
    let file: CourseResourceFile
    let icon: String
    let isLoading: Bool

    var body: some View {
        LearnGlassCard {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.filename)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                        .lineLimit(2)
                    Text(file.sizeLabel)
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                Spacer(minLength: 4)
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
        }
    }
}

private struct LearnCourseHTMLBody: View {
    let html: String
    let courseFiles: [CourseResourceFile]
    let headerImageUUID: String?
    var onOpenFile: ((CourseResourceFile) -> Void)?

    @State private var contentHeight: CGFloat = 120

    var body: some View {
        let prepared = LearnCourseHTMLPreprocessor.prepare(
            html,
            courseFiles: courseFiles,
            headerImageUUID: headerImageUUID
        )
        LearnHTMLContentView(
            html: prepared,
            minHeight: 80,
            variant: .course,
            contentHeight: $contentHeight,
            onCourseFileURL: { url in
                guard let uuid = url.host, !uuid.isEmpty,
                      let file = courseFiles.first(where: { $0.uuid == uuid }) else { return }
                onOpenFile?(file)
            }
        )
        .frame(height: contentHeight)
    }
}

struct LearnCourseModuleStack: View {
    let blocks: [CourseRenderedBlock]
    let accent: Color
    var courseFiles: [CourseResourceFile] = []
    var headerImageUUID: String?
    var downloadingFileUUID: String?
    var onOpenFile: ((CourseResourceFile) -> Void)?

    var body: some View {
        if blocks.isEmpty {
            LearnEmptyState(
                title: "No content",
                message: "This section does not have published modules yet."
            )
            .frame(maxWidth: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                    LearnCourseModuleView(
                        block: block,
                        accent: accent,
                        courseFiles: courseFiles,
                        headerImageUUID: headerImageUUID,
                        downloadingFileUUID: downloadingFileUUID,
                        onOpenFile: onOpenFile
                    )
                    .learnListEntrance(index: index)
                }
            }
        }
    }
}

private struct LearnCourseModuleView: View {
    let block: CourseRenderedBlock
    let accent: Color
    var courseFiles: [CourseResourceFile] = []
    var headerImageUUID: String?
    var downloadingFileUUID: String?
    var onOpenFile: ((CourseResourceFile) -> Void)?

    var body: some View {
        switch block {
        case .title(let text):
            Text(text)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .html(let html):
            LearnGlassCard {
                LearnCourseHTMLBody(
                    html: html,
                    courseFiles: courseFiles,
                    headerImageUUID: headerImageUUID,
                    onOpenFile: onOpenFile
                )
            }
        case .link(let urlString):
            if let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                        Text(urlString)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LearnTheme.Colors.accent)
                    .padding(14)
                    .learnGroupedGlass(cornerRadius: 12)
                }
            }
        case .resources(let files):
            VStack(alignment: .leading, spacing: 8) {
                Text("Resources")
                    .font(.headline)
                ForEach(files) { file in
                    Button {
                        LearnHaptics.lightImpact()
                        onOpenFile?(file)
                    } label: {
                        LearnCourseResourceFileRow(
                            file: file,
                            icon: "📎",
                            isLoading: downloadingFileUUID == file.uuid
                        )
                    }
                    .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))
                    .disabled(downloadingFileUUID != nil)
                }
            }
        case .formula(let expression):
            LearnGlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Formula")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    Text(expression)
                        .font(.body.monospaced())
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                        .learnReadableBody()
                }
            }
        case .poll(let proposition, let options):
            LearnGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(proposition)
                        .font(.subheadline.weight(.semibold))
                    if options.isEmpty {
                        Text("No options published.")
                            .font(.footnote)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    } else {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            Text("\(index + 1). \(option)")
                                .font(.subheadline)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                        }
                    }
                }
            }
        }
    }
}
