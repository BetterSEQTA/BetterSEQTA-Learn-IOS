import Combine
import CoreDesign
import Domain
import SwiftUI

public struct LearnTimetableView: View {
    @State private var viewModel: LearnTimetableViewModel
    @State private var now = Date()
    @State private var weekPagerPage = 0
    @Environment(\.learnMotionProfile) private var motionProfile

    private let nowTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    public init(viewModel: LearnTimetableViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            timetableChrome
            content
        }
        .background { LearnScreenBackground() }
        .learnShellNavigationDepth(0)
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .onReceive(nowTimer) { tick in
            now = tick
        }
    }

    private var timetableChrome: some View {
        VStack(alignment: .leading, spacing: 6) {
            LearnTimetableWeekPager(
                page: $weekPagerPage,
                viewModel: viewModel,
                onSelectDay: { viewModel.selectDate($0) }
            )

            LearnUnderlineSegmentBar(
                items: LearnTimetableDisplayMode.allCases.map { ($0, $0.label) },
                selection: viewModel.displayMode,
                density: .compact,
                style: .fluid
            ) { mode in
                viewModel.selectDisplayMode(mode)
            }
            .padding(.horizontal, LearnLayout.horizontalPadding)
        }
        .padding(.top, 2)
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            LearnSeparatorHairline()
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if viewModel.isLoading, viewModel.lessons.isEmpty {
                LearnLoadingState(preset: .timetableDay)
            } else if let error = viewModel.errorMessage, viewModel.lessons.isEmpty {
                LearnErrorBanner(message: error) {
                    Task { await viewModel.refresh() }
                }
            } else if viewModel.lessons.isEmpty {
                LearnEmptyState(
                    title: "No lessons",
                    message: viewModel.isSelectedDateToday
                        ? "You're free for the rest of the day."
                        : "Nothing scheduled on this day."
                )
                .frame(maxHeight: .infinity)
            } else if viewModel.displayMode == .day {
                dayScheduleBody
            } else {
                agendaScrollBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(LearnMotion.spatialStandardDefault, value: viewModel.displayMode)
    }

    private var agendaScrollBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                spotlightSection
                LearnDirectionalContent(
                    identity: viewModel.selectedDate,
                    direction: viewModel.dayNavigationDirection
                ) {
                    LearnTimetableAgendaList(
                        lessons: viewModel.lessons,
                        phase: { viewModel.phase(for: $0, now: now) }
                    )
                }
            }
            .padding(.bottom, 24)
        }
    }

    private var dayScheduleBody: some View {
        VStack(spacing: 0) {
            if viewModel.isSelectedDateToday, let spotlight = viewModel.spotlightLesson(now: now) {
                LearnTimetableSpotlightCard(
                    lesson: spotlight,
                    phase: viewModel.phase(for: spotlight, now: now),
                    minutesUntil: viewModel.minutesUntilStart(of: spotlight, now: now),
                    compact: true
                )
                .padding(.horizontal, LearnLayout.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            LearnDirectionalContent(
                identity: viewModel.selectedDate,
                direction: viewModel.dayNavigationDirection
            ) {
                LearnTimetableDayGrid(
                    lessons: viewModel.lessons,
                    showNowIndicator: viewModel.isSelectedDateToday,
                    referenceDate: now,
                    lessonState: { lesson in
                        switch viewModel.phase(for: lesson, now: now) {
                        case .past: return .past
                        case .current: return .current
                        case .upcoming: return .upcoming
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var spotlightSection: some View {
        if let spotlight = viewModel.spotlightLesson(now: now) {
            LearnTimetableSpotlightCard(
                lesson: spotlight,
                phase: viewModel.phase(for: spotlight, now: now),
                minutesUntil: viewModel.minutesUntilStart(of: spotlight, now: now),
                compact: false
            )
            .padding(.horizontal, LearnLayout.horizontalPadding)
            .padding(.top, 12)
        }
    }
}

// MARK: - Week pager (swipe changes week)

private struct LearnTimetableWeekPager: View {
    @Binding var page: Int
    let viewModel: LearnTimetableViewModel
    let onSelectDay: (Date) -> Void

    @Namespace private var dayHighlight

    private let pages = [-1, 0, 1]

    var body: some View {
        VStack(spacing: 4) {
            TabView(selection: $page) {
                ForEach(pages, id: \.self) { offset in
                    weekRow(days: viewModel.weekDays(pageOffset: offset))
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            LearnFluidPageIndicator(count: 3, index: page + 1)
        }
        .frame(height: 62)
        .onChange(of: page) { _, newPage in
            guard newPage != 0 else { return }
            LearnHaptics.selection()
            viewModel.shiftWeek(by: newPage > 0 ? 1 : -1)
            LearnMotion.withoutAnimation {
                page = 0
            }
        }
    }

    private func weekRow(days: [Date]) -> some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                dayCell(day)
            }
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .frame(maxWidth: .infinity)
    }

    private func dayCell(_ day: Date) -> some View {
        let calendar = Calendar.current
        let isSelected = calendar.isDate(day, inSameDayAs: viewModel.selectedDate)
        let isToday = calendar.isDateInToday(day)
        return Button {
            LearnHaptics.selection()
            withAnimation(LearnMotion.spatialStandardDefault) {
                onSelectDay(day)
            }
        } label: {
            VStack(spacing: 3) {
                Text(day, format: .dateTime.weekday(.narrow))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(
                        isSelected
                            ? LearnTheme.Colors.primaryText
                            : LearnTheme.Colors.secondaryText
                    )
                ZStack {
                    if isToday && !isSelected {
                        Circle()
                            .strokeBorder(LearnTheme.Colors.accent.opacity(0.55), lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                    }
                    Text(day, format: .dateTime.day())
                        .font(.subheadline.weight(isSelected ? .bold : .medium))
                        .monospacedDigit()
                        .foregroundStyle(LearnTheme.Colors.primaryText.opacity(isSelected ? 1 : 0.85))
                        .frame(width: 30, height: 30)
                        .background {
                            if isSelected {
                                Circle()
                                    .fill(LearnTheme.Colors.accent.opacity(0.22))
                                    .matchedGeometryEffect(id: "dayBubble", in: dayHighlight)
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.96))
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Spotlight

private struct LearnTimetableSpotlightCard: View {
    let lesson: TimetableLesson
    let phase: LearnLessonPhase
    let minutesUntil: Int?
    var compact: Bool = false

    private var accent: Color { LearnSubjectColour.parse(lesson.colour) }

    private var headline: String {
        switch phase {
        case .current: return "Now"
        case .upcoming: return "Up next"
        case .past: return "Later"
        }
    }

    private var subline: String? {
        switch phase {
        case .current:
            return lesson.displayTimeRange
        case .upcoming:
            if let minutesUntil {
                return minutesUntil < 60
                    ? "Starts in \(minutesUntil) min"
                    : "Starts in \(minutesUntil / 60)h \(minutesUntil % 60)m"
            }
            return lesson.displayTimeRange
        case .past:
            return nil
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: compact ? 10 : 14) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accent)
                .frame(width: compact ? 4 : 5)
            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                HStack(spacing: 8) {
                    Text(headline.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(phase == .current ? accent : LearnTheme.Colors.accent)
                    if phase == .current {
                        Circle()
                            .fill(accent)
                            .frame(width: 6, height: 6)
                    }
                }
                Text(lesson.title)
                    .font(compact ? .body.weight(.semibold) : .title3.weight(.semibold))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .lineLimit(compact ? 1 : 2)
                if let subline {
                    Text(subline)
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                if let teacher = lesson.teacherName, !teacher.isEmpty {
                    Label(teacher, systemImage: "person")
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(compact ? 1 : 2)
                }
                if let room = lesson.room, !room.isEmpty {
                    Label(room, systemImage: "mappin.and.ellipse")
                        .font(compact ? .caption : .subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(compact ? 12 : 16)
        .background {
            RoundedRectangle(cornerRadius: LearnTheme.cardCornerRadius, style: .continuous)
                .fill(accent.opacity(phase == .current ? 0.16 : 0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: LearnTheme.cardCornerRadius, style: .continuous)
                .strokeBorder(accent.opacity(phase == .current ? 0.45 : 0.2), lineWidth: 1)
        }
    }
}

// MARK: - Agenda

struct LearnTimetableAgendaList: View {
    let lessons: [TimetableLesson]
    let phase: (TimetableLesson) -> LearnLessonPhase

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                LearnTimetableAgendaRow(
                    lesson: lesson,
                    phase: phase(lesson),
                    isLast: index == lessons.count - 1
                )
                .learnListEntrance(index: index)
            }
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .padding(.top, 8)
    }
}

private struct LearnTimetableAgendaRow: View {
    let lesson: TimetableLesson
    let phase: LearnLessonPhase
    let isLast: Bool

    private var accent: Color { LearnSubjectColour.parse(lesson.colour) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timelineColumn
            lessonCard
        }
        .padding(.bottom, isLast ? 0 : 14)
    }

    private var timelineColumn: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .strokeBorder(
                        phase == .current ? accent : LearnTheme.Colors.glassStroke,
                        lineWidth: phase == .current ? 2.5 : 1
                    )
                    .background(
                        Circle()
                            .fill(phase == .current ? accent.opacity(0.35) : LearnTheme.Colors.background)
                    )
                    .frame(width: 12, height: 12)
                if phase == .current {
                    Circle()
                        .fill(accent)
                        .frame(width: 5, height: 5)
                }
            }
            if !isLast {
                Rectangle()
                    .fill(LearnTheme.Colors.glassStroke.opacity(0.5))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 4)
            }
        }
        .frame(width: 12)
        .padding(.top, 18)
    }

    private var lessonCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let range = lesson.displayTimeRange {
                Text(range)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(
                        phase == .current
                            ? accent
                            : (phase == .past ? LearnTheme.Colors.tertiaryText : LearnTheme.Colors.secondaryText)
                    )
            }
            Text(lesson.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(
                    phase == .past ? LearnTheme.Colors.secondaryText : LearnTheme.Colors.primaryText
                )
            if let teacher = lesson.teacherName, !teacher.isEmpty {
                Label(teacher, systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
            if let room = lesson.room, !room.isEmpty {
                Label(room, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                .fill(
                    phase == .current
                        ? accent.opacity(0.14)
                        : LearnTheme.Colors.groupedFill.opacity(0.5)
                )
        }
        .overlay {
            if phase == .current {
                RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                    .strokeBorder(accent.opacity(0.4), lineWidth: 1)
            }
        }
    }
}

extension TimetableLesson: Identifiable {}
