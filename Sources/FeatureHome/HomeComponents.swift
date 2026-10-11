import CoreDesign
import Domain
import SwiftUI

struct DashboardSectionHeader: View {
    let title: String
    let subtitle: String
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil
    var trailing: (() -> AnyView)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
            Spacer(minLength: 8)
            if let trailing {
                trailing()
            }
            if let actionLabel, let onAction {
                Button(actionLabel, action: onAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct HomeDashboardHeader: View {
    var displayName: String?

    private let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE · d MMMM yyyy"
        return f
    }()

    var body: some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let greeting = switch hour {
        case 0 ... 11: "Good morning"
        case 12 ... 16: "Good afternoon"
        default: "Good evening"
        }

        VStack(alignment: .leading, spacing: 4) {
            Text(headerDateFormatter.string(from: now))
                .font(.caption)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            Text(displayName.map { "\(greeting), \($0)" } ?? greeting)
                .font(.title2.weight(.bold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text("Your day at a glance")
                .font(.subheadline)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct HomeShortcutsRow: View {
    let navigation: HomeNavigationCallbacks

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardSectionHeader(
                title: "Shortcuts",
                subtitle: "Quick navigation"
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    shortcutChip("Portals", systemImage: "globe", action: navigation.onPortalsClick)
                    shortcutChip("Notices", systemImage: "megaphone", action: navigation.onNoticesClick)
                    shortcutChip("Timetable", systemImage: "calendar", action: navigation.onTimetableClick)
                    shortcutChip("Courses", systemImage: "book", action: navigation.onCoursesClick)
                    shortcutChip("Tasks", systemImage: "doc.text", action: navigation.onAssessmentsClick)
                    shortcutChip("Messages", systemImage: "envelope", action: navigation.onMessagesClick)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func shortcutChip(_ label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(LearnTheme.Colors.card, in: Capsule())
                .foregroundStyle(LearnTheme.Colors.primaryText)
        }
        .buttonStyle(.plain)
    }
}

struct HomeLessonCard: View {
    let lesson: TimetableLesson

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(HomeColourUtils.parseSubjectColour(lesson.colour))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                Text(lesson.subjectCode)
                    .font(.caption)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
                if let room = lesson.room, !room.isEmpty {
                    Label(room, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct HomeNoticeCard: View {
    let notice: Notice
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(HomeColourUtils.parseSubjectColour(notice.colour))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 4) {
                    Text(notice.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                    if let label = notice.labelTitle {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HomeAssessmentCard: View {
    let assessment: Assessment
    let colour: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colour)
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: 6) {
                    Text(assessment.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Text(assessment.subjectCode)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colour.opacity(0.25), in: Capsule())
                        if let status = assessment.status?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !status.isEmpty {
                            Text(status)
                                .font(.caption2)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                        }
                    }
                    if let due = assessment.dueDate, !due.isEmpty {
                        Label("Due \(due)", systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HomeSubjectFilterRow: View {
    let subjectsState: SectionLoadState<[Subject]>
    let selectedSubjectCode: String?
    let onSelect: (String?) -> Void

    var body: some View {
        if case let .success(subjects) = subjectsState, !subjects.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "All", colour: nil, selected: selectedSubjectCode == nil) {
                        onSelect(nil)
                    }
                    ForEach(subjects, id: \.code) { subject in
                        let selected = selectedSubjectCode == subject.code
                        filterChip(
                            label: subject.code,
                            colour: HomeColourUtils.parseSubjectColour(subject.colour),
                            selected: selected
                        ) {
                            onSelect(selected ? nil : subject.code)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
    }

    private func filterChip(
        label: String,
        colour: Color?,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let colour {
                    Circle()
                        .fill(colour)
                        .frame(width: 8, height: 8)
                }
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(chipBackground(selected: selected, accent: colour), in: Capsule())
            .overlay {
                if selected, let colour {
                    Capsule()
                        .strokeBorder(colour.opacity(0.8), lineWidth: 1.5)
                }
            }
            .foregroundStyle(LearnTheme.Colors.primaryText)
        }
        .buttonStyle(.plain)
    }

    private func chipBackground(selected: Bool, accent: Color?) -> Color {
        if selected {
            return (accent ?? Color.accentColor).opacity(0.28)
        }
        return LearnTheme.Colors.card
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
                .tint(Color.accentColor)
        }
        .padding(.horizontal, 16)
    }
}

struct HomeSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LearnTheme.Colors.card)
            .frame(height: 56)
            .opacity(0.6)
    }
}

func lessonSectionTitle(for date: Date) -> String {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let target = calendar.startOfDay(for: date)
    if target == today { return "Today's Lessons" }
    if target == calendar.date(byAdding: .day, value: 1, to: today) { return "Tomorrow's Lessons" }
    if target == calendar.date(byAdding: .day, value: -1, to: today) { return "Yesterday's Lessons" }
    return "Lessons"
}

private let lessonSubtitleFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE, d MMM"
    return f
}()

func lessonSectionSubtitle(for date: Date) -> String {
    lessonSubtitleFormatter.string(from: date)
}
