import CoreDesign
import Domain
import SwiftUI

typealias DashboardSectionHeader = LearnSectionHeader

struct HomeDashboardHeader: View {
    var displayName: String?

    var body: some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let greeting = switch hour {
        case 0 ... 11: "Good morning"
        case 12 ... 16: "Good afternoon"
        default: "Good evening"
        }

        VStack(alignment: .leading, spacing: 4) {
            Text(displayName.map { "\(greeting), \($0)" } ?? greeting)
                .font(LearnTypography.screenTitle)
                .foregroundStyle(LearnTheme.Colors.primaryText)
                .learnReadableTitle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .learnHeaderScrollFade()
    }
}

struct HomeFilterMenus: View {
    let subjectsState: SectionLoadState<[Subject]>
    let selectedSubjectCode: String?
    let onSelectSubject: (String?) -> Void
    let navigation: HomeNavigationCallbacks

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                subjectMenu
                browseMenu
                Spacer(minLength: 0)
            }
            subjectChipRail
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var subjectChipRail: some View {
        if case let .success(subjects) = subjectsState, subjects.count > 1 {
            let chips = ["All"] + subjects.map(\.code)
            LearnMorphingFilterChips(
                chips: chips,
                selection: Binding(
                    get: { selectedSubjectCode },
                    set: { code in onSelectSubject(code == "All" || code == nil ? nil : code) }
                ),
                defaultChip: "All"
            )
        }
    }

    @ViewBuilder
    private var subjectMenu: some View {
        if case let .success(subjects) = subjectsState, !subjects.isEmpty {
            Menu {
                Button("All subjects") { onSelectSubject(nil) }
                Divider()
                ForEach(subjects, id: \.code) { subject in
                    Button(subject.code) {
                        onSelectSubject(
                            selectedSubjectCode == subject.code ? nil : subject.code
                        )
                    }
                }
            } label: {
                menuLabel(
                    title: selectedSubjectCode ?? "All subjects",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }
        }
    }

    private var browseMenu: some View {
        Menu {
            Button("Timetable", systemImage: "calendar", action: navigation.onTimetableClick)
            Button("Courses", systemImage: "book", action: navigation.onCoursesClick)
            Button("Tasks", systemImage: "checklist", action: navigation.onAssessmentsClick)
            Button("Messages", systemImage: "envelope", action: navigation.onMessagesClick)
            Divider()
            Button("Portals", systemImage: "globe", action: navigation.onPortalsClick)
            Button("Notices", systemImage: "megaphone", action: navigation.onNoticesClick)
        } label: {
            menuLabel(title: "Browse", systemImage: "square.grid.2x2")
        }
    }

    private func menuLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(LearnTypography.rowBody.weight(.medium))
            .foregroundStyle(LearnTheme.Colors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .learnGroupedGlass(cornerRadius: LearnTheme.controlCornerRadius)
            .learnPressFeedback(scale: 0.97)
    }
}

struct HomeLessonCard: View {
    let lesson: TimetableLesson

    var body: some View {
        LearnListRow(
            accent: HomeColourUtils.parseSubjectColour(lesson.colour),
            title: lesson.title,
            subtitle: lesson.displayTimeRange,
            detail: lesson.subjectCode,
            footnote: lesson.room
        )
        .padding(.horizontal, LearnTheme.Spacing.md)
        .padding(.vertical, 12)
    }
}

struct HomeNoticeCard: View {
    let notice: Notice
    let onTap: () -> Void

    var body: some View {
        Button {
            LearnHaptics.lightImpact()
            onTap()
        } label: {
            LearnListRow(
                accent: HomeColourUtils.parseSubjectColour(notice.colour),
                title: notice.title,
                subtitle: notice.labelTitle,
                detail: notice.contentPreview(maxLength: 100),
                footnote: notice.staff
            )
            .padding(.horizontal, LearnTheme.Spacing.md)
            .padding(.vertical, 12)
        }
        .learnRowPress()
    }
}

struct HomeAssessmentCard: View {
    let assessment: Assessment
    let colour: Color
    let onTap: () -> Void

    var body: some View {
        Button {
            LearnHaptics.lightImpact()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                LearnListRow(
                    accent: colour,
                    title: assessment.title,
                    subtitle: assessment.subjectCode,
                    detail: assessment.dueDate.map { "Due \($0)" }
                )
                LearnStatusChip(assessment.listDisplayStatus().rawValue, tint: colour)
            }
            .padding(.horizontal, LearnTheme.Spacing.md)
            .padding(.vertical, 12)
        }
        .learnRowPress()
    }
}

struct HomeSectionMessage: View {
    let message: String
    var secondary: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            if let secondary {
                Text(secondary)
                    .font(.caption)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
        }
        .padding(.horizontal, LearnTheme.Spacing.md)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeFluidLoader: View {
    let progress: Float
    let phaseText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(phaseText)
                .font(.caption)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            ProgressView(value: Double(progress))
                .tint(LearnTheme.Colors.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LearnSkeletonBlock(height: 28, width: 200)
            LearnSkeletonBlock(height: 14, width: 140)
            ForEach(0 ..< 4, id: \.self) { index in
                LearnSkeletonBlock(height: 72)
                    .learnListEntrance(index: index)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

func lessonSectionTitle(for date: Date) -> String {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let target = calendar.startOfDay(for: date)
    if target == today { return "Today" }
    if target == calendar.date(byAdding: .day, value: 1, to: today) { return "Tomorrow" }
    if target == calendar.date(byAdding: .day, value: -1, to: today) { return "Yesterday" }
    return "Schedule"
}

private let lessonSubtitleFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE, d MMM"
    return f
}()

func lessonSectionSubtitle(for date: Date) -> String {
    lessonSubtitleFormatter.string(from: date)
}
