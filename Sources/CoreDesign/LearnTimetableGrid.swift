import Domain
import SwiftUI

public enum LearnTimetableLessonVisualState: Sendable, Equatable {
    case past
    case current
    case upcoming
}

/// Proportional day column: block height matches lesson duration; overlapping lessons share width.
public struct LearnTimetableDayGrid: View {
    public let lessons: [TimetableLesson]
    public let minuteHeight: CGFloat
    public let showNowIndicator: Bool
    public let referenceDate: Date
    public let lessonState: (TimetableLesson) -> LearnTimetableLessonVisualState

    public init(
        lessons: [TimetableLesson],
        minuteHeight: CGFloat = 1.45,
        showNowIndicator: Bool = false,
        referenceDate: Date = .now,
        lessonState: @escaping (TimetableLesson) -> LearnTimetableLessonVisualState = { _ in .upcoming }
    ) {
        self.lessons = lessons
        self.minuteHeight = minuteHeight
        self.showNowIndicator = showNowIndicator
        self.referenceDate = referenceDate
        self.lessonState = lessonState
    }

    public var body: some View {
        let layout = LearnTimetableDayLayout(lessons: lessons, minuteHeight: minuteHeight)
        let placements = LearnTimetableConflictLayout.placements(
            lessons: lessons,
            layout: layout,
            horizontalGap: 5
        )
        let nowOffset = showNowIndicator ? layout.yOffset(for: referenceDate) : nil
        let scrollAnchor = scrollTargetOffset(layout: layout, nowOffset: nowOffset)

        ScrollViewReader { proxy in
            ScrollView {
                HStack(alignment: .top, spacing: 10) {
                    timeRail(layout: layout)

                    GeometryReader { geometry in
                        let columnWidth = geometry.size.width

                        ZStack(alignment: .topLeading) {
                            hourBands(layout: layout)

                            ForEach(layout.hourMarkers.indices, id: \.self) { index in
                                Rectangle()
                                    .fill(LearnTheme.Colors.glassStroke.opacity(0.5))
                                    .frame(height: 0.5)
                                    .offset(y: CGFloat(index) * 60 * minuteHeight)
                            }

                            ForEach(placements, id: \.lesson.id) { placement in
                                LearnTimetableBlock(
                                    lesson: placement.lesson,
                                    visualState: lessonState(placement.lesson)
                                )
                                .frame(
                                    width: placement.rect.width * columnWidth,
                                    height: placement.rect.height,
                                    alignment: .topLeading
                                )
                                .offset(
                                    x: placement.rect.minX * columnWidth,
                                    y: placement.rect.minY
                                )
                            }

                            if let nowOffset, nowOffset >= 0, nowOffset <= layout.totalHeight {
                                LearnTimetableNowLine()
                                    .offset(y: nowOffset)
                                    .id("timetable-now")
                            }

                            Color.clear
                                .frame(width: 1, height: 1)
                                .offset(y: scrollAnchor)
                                .id("timetable-scroll-anchor")
                        }
                        .frame(width: columnWidth, height: layout.totalHeight, alignment: .topLeading)
                    }
                    .frame(height: layout.totalHeight)
                }
                .padding(.horizontal, LearnLayout.horizontalPadding)
                .padding(.vertical, LearnTheme.Spacing.sm)
                .padding(.bottom, 24)
            }
            .onAppear {
                scrollToAnchor(proxy: proxy, offset: scrollAnchor, layout: layout)
            }
            .onChange(of: lessons) { _, _ in
                scrollToAnchor(proxy: proxy, offset: scrollAnchor, layout: layout)
            }
        }
    }

    private func timeRail(layout: LearnTimetableDayLayout) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(layout.hourMarkers, id: \.self) { marker in
                Text(marker)
                    .font(.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
                    .frame(height: 60 * minuteHeight, alignment: .top)
                    .padding(.top, -2)
            }
        }
        .frame(width: 40)
    }

    private func hourBands(layout: LearnTimetableDayLayout) -> some View {
        ForEach(layout.hourMarkers.indices, id: \.self) { index in
            if index.isMultiple(of: 2) {
                Rectangle()
                    .fill(LearnTheme.Colors.groupedFill.opacity(0.35))
                    .frame(height: 60 * minuteHeight)
                    .offset(y: CGFloat(index) * 60 * minuteHeight)
            }
        }
    }

    private func scrollTargetOffset(layout: LearnTimetableDayLayout, nowOffset: CGFloat?) -> CGFloat {
        if let nowOffset, nowOffset >= 0, nowOffset <= layout.totalHeight {
            return max(0, nowOffset - 120)
        }
        if let first = lessons.first, let frame = layout.frame(for: first) {
            return max(0, frame.minY - 24)
        }
        return 0
    }

    private func scrollToAnchor(proxy: ScrollViewProxy, offset: CGFloat, layout: LearnTimetableDayLayout) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(LearnMotion.spatialStandardDefault) {
                proxy.scrollTo("timetable-scroll-anchor", anchor: .top)
            }
        }
    }
}

private struct LearnTimetableNowLine: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(LearnTheme.Colors.accent)
                .frame(width: 9, height: 9)
                .shadow(color: LearnTheme.Colors.accent.opacity(0.45), radius: 4)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [LearnTheme.Colors.accent, LearnTheme.Colors.accent.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Current time")
    }
}

struct LearnTimetableBlock: View {
    let lesson: TimetableLesson
    let visualState: LearnTimetableLessonVisualState

    private var accent: Color {
        LearnSubjectColour.parse(lesson.colour)
    }

    private var isCompact: Bool {
        lesson.durationMinutes < 40
    }

    private var opacity: Double {
        switch visualState {
        case .past: 0.55
        case .current: 1
        case .upcoming: 0.92
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: visualState == .current ? 4 : 3)
            VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
                HStack(spacing: 6) {
                    if let range = lesson.displayTimeRange {
                        Text(range)
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(
                                visualState == .current ? accent : LearnTheme.Colors.secondaryText
                            )
                            .lineLimit(1)
                    }
                    if !lesson.subjectCode.isEmpty, !isCompact {
                        Text(lesson.subjectCode)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(accent.opacity(0.15), in: Capsule())
                    }
                }
                Text(lesson.title)
                    .font(isCompact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .lineLimit(isCompact ? 2 : 3)
                    .minimumScaleFactor(0.8)
                if !isCompact {
                    if let teacher = lesson.teacherName, !teacher.isEmpty {
                        Label(teacher, systemImage: "person")
                            .font(.caption2)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                            .lineLimit(1)
                    }
                    if let room = lesson.room, !room.isEmpty {
                        Label(room, systemImage: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                            .lineLimit(1)
                    }
                } else if let room = lesson.room, !room.isEmpty {
                    Text(room)
                        .font(.caption2)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, isCompact ? 5 : 8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .opacity(opacity)
        .background(
            RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                .fill(accent.opacity(visualState == .current ? 0.22 : 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                .strokeBorder(
                    accent.opacity(visualState == .current ? 0.55 : 0.25),
                    lineWidth: visualState == .current ? 1.5 : 1
                )
        )
        .shadow(
            color: visualState == .current ? accent.opacity(0.25) : .clear,
            radius: visualState == .current ? 6 : 0,
            y: 2
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        [lesson.title, lesson.displayTimeRange, lesson.room, lesson.teacherName]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

struct LearnTimetableDayLayout {
    let lessons: [TimetableLesson]
    let minuteHeight: CGFloat
    let dayStart: Date
    let totalHeight: CGFloat
    let hourMarkers: [String]

    init(lessons: [TimetableLesson], minuteHeight: CGFloat) {
        self.lessons = lessons
        self.minuteHeight = minuteHeight
        let intervals = lessons.compactMap { $0.intervalOnLessonDay() }
        let calendar = Calendar.current
        if let first = intervals.map(\.start).min(), let last = intervals.map(\.end).max() {
            let startHour = calendar.component(.hour, from: first)
            let alignedStart = calendar.date(
                bySettingHour: max(7, startHour - 1),
                minute: 0,
                second: 0,
                of: first
            ) ?? first
            let endHour = calendar.component(.hour, from: last)
            let endMinute = calendar.component(.minute, from: last)
            let paddedEndHour = endMinute > 0 ? endHour + 1 : endHour
            let alignedEnd = calendar.date(
                bySettingHour: min(18, paddedEndHour + 1),
                minute: 0,
                second: 0,
                of: last
            ) ?? last.addingTimeInterval(3600)
            dayStart = alignedStart
            let minutes = max(60, alignedEnd.timeIntervalSince(alignedStart) / 60)
            totalHeight = CGFloat(minutes) * minuteHeight
            hourMarkers = Self.markers(from: alignedStart, to: alignedEnd, calendar: calendar)
        } else {
            dayStart = calendar.startOfDay(for: Date()).addingTimeInterval(8 * 3600)
            totalHeight = 540 * minuteHeight
            hourMarkers = (8 ... 15).map { Self.friendlyHourLabel(hour: $0) }
        }
    }

    func frame(for lesson: TimetableLesson) -> CGRect? {
        guard let interval = lesson.intervalOnLessonDay() else { return nil }
        let startMinutes = interval.start.timeIntervalSince(dayStart) / 60
        let durationMinutes = interval.end.timeIntervalSince(interval.start) / 60
        let minY = CGFloat(startMinutes) * minuteHeight
        let height = max(36, CGFloat(durationMinutes) * minuteHeight - 3)
        return CGRect(x: 0, y: minY, width: 1, height: height)
    }

    func yOffset(for date: Date) -> CGFloat {
        let minutes = date.timeIntervalSince(dayStart) / 60
        return CGFloat(minutes) * minuteHeight
    }

    private static func markers(from start: Date, to end: Date, calendar: Calendar) -> [String] {
        var markers: [String] = []
        var cursor = start
        while cursor <= end {
            markers.append(friendlyHourLabel(date: cursor, calendar: calendar))
            guard let next = calendar.date(byAdding: .hour, value: 1, to: cursor) else { break }
            cursor = next
        }
        return markers
    }

    private static func friendlyHourLabel(hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return friendlyHourLabel(date: date, calendar: Calendar.current)
    }

    private static func friendlyHourLabel(date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }
}

struct LearnTimetableConflictLayout {
    struct Placement {
        let lesson: TimetableLesson
        let rect: CGRect
    }

    static func placements(
        lessons: [TimetableLesson],
        layout: LearnTimetableDayLayout,
        horizontalGap: CGFloat
    ) -> [Placement] {
        let sorted = lessons.sorted { ($0.fromTime ?? "") < ($1.fromTime ?? "") }
        let columns = assignColumns(sorted)
        var result: [Placement] = []

        for lesson in sorted {
            guard let base = layout.frame(for: lesson) else { continue }
            let overlapping = sorted.filter { other in
                guard other.id != lesson.id,
                      let a = lesson.intervalOnLessonDay(),
                      let b = other.intervalOnLessonDay() else { return false }
                return a.start < b.end && b.start < a.end
            }
            let clusterColumns = ([lesson] + overlapping).compactMap { columns[$0.id] }
            let columnCount = max(1, (clusterColumns.max() ?? 0) + 1)
            let columnIndex = columns[lesson.id] ?? 0
            let unit = 1 / CGFloat(columnCount)
            let width = unit - (horizontalGap / 320)
            let x = unit * CGFloat(columnIndex)
            let rect = CGRect(x: x, y: base.minY, width: max(0.12, width), height: base.height)
            result.append(Placement(lesson: lesson, rect: rect))
        }
        return result
    }

    private static func assignColumns(_ lessons: [TimetableLesson]) -> [String: Int] {
        var columnEnds: [Date] = []
        var result: [String: Int] = [:]

        for lesson in lessons {
            guard let interval = lesson.intervalOnLessonDay() else { continue }
            var column = 0
            while column < columnEnds.count, columnEnds[column] > interval.start {
                column += 1
            }
            if column == columnEnds.count {
                columnEnds.append(interval.end)
            } else {
                columnEnds[column] = interval.end
            }
            result[lesson.id] = column
        }
        return result
    }
}
