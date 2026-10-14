import Domain
import SwiftUI

/// Proportional day column: block height matches lesson duration; overlapping lessons share width.
public struct LearnTimetableDayGrid: View {
    public let lessons: [TimetableLesson]
    public let minuteHeight: CGFloat
    public let showNowIndicator: Bool
    public let referenceDate: Date

    public init(
        lessons: [TimetableLesson],
        minuteHeight: CGFloat = 1.2,
        showNowIndicator: Bool = false,
        referenceDate: Date = .now
    ) {
        self.lessons = lessons
        self.minuteHeight = minuteHeight
        self.showNowIndicator = showNowIndicator
        self.referenceDate = referenceDate
    }

    public var body: some View {
        let layout = LearnTimetableDayLayout(lessons: lessons, minuteHeight: minuteHeight)
        let placements = LearnTimetableConflictLayout.placements(
            lessons: lessons,
            layout: layout,
            horizontalGap: 4
        )
        let nowOffset = showNowIndicator ? layout.yOffset(for: referenceDate) : nil

        ScrollView {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(layout.hourMarkers, id: \.self) { marker in
                        Text(marker)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                            .frame(height: 60 * minuteHeight, alignment: .top)
                    }
                }
                .frame(width: 44)

                GeometryReader { geometry in
                    let columnWidth = geometry.size.width

                    ZStack(alignment: .topLeading) {
                        ForEach(layout.hourMarkers.indices, id: \.self) { index in
                            Rectangle()
                                .fill(LearnTheme.Colors.glassStroke.opacity(0.45))
                                .frame(height: 0.5)
                                .offset(y: CGFloat(index) * 60 * minuteHeight)
                        }

                        ForEach(placements, id: \.lesson.id) { placement in
                            LearnTimetableBlock(lesson: placement.lesson)
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
                        }
                    }
                    .frame(width: columnWidth, height: layout.totalHeight, alignment: .topLeading)
                }
                .frame(height: layout.totalHeight)
            }
            .padding(.horizontal, LearnLayout.horizontalPadding)
            .padding(.vertical, LearnTheme.Spacing.sm)
        }
    }
}

private struct LearnTimetableNowLine: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(LearnTheme.Colors.accent)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(LearnTheme.Colors.accent)
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Current time")
    }
}

struct LearnTimetableBlock: View {
    let lesson: TimetableLesson

    private var accent: Color {
        LearnSubjectColour.parse(lesson.colour)
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 3) {
                if let range = lesson.displayTimeRange {
                    Text(range)
                        .font(.caption2.monospacedDigit().weight(.medium))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
                Text(lesson.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                if let teacher = lesson.teacherName, !teacher.isEmpty, lesson.durationMinutes >= 35 {
                    Text(teacher)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
                if let room = lesson.room, !room.isEmpty, lesson.durationMinutes >= 50 {
                    Label(room, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(1)
                        .labelStyle(.titleAndIcon)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                .fill(accent.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
                .strokeBorder(accent.opacity(0.28), lineWidth: 1)
        )
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
            let alignedEnd = calendar.date(
                bySettingHour: min(18, endHour + 1),
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
            totalHeight = 600 * minuteHeight
            hourMarkers = (8 ... 16).map { String(format: "%02d:00", $0) }
        }
    }

    func frame(for lesson: TimetableLesson) -> CGRect? {
        guard let interval = lesson.intervalOnLessonDay() else { return nil }
        let startMinutes = interval.start.timeIntervalSince(dayStart) / 60
        let durationMinutes = interval.end.timeIntervalSince(interval.start) / 60
        let minY = CGFloat(startMinutes) * minuteHeight
        let height = max(40, CGFloat(durationMinutes) * minuteHeight - 4)
        return CGRect(x: 0, y: minY, width: 1, height: height)
    }

    func yOffset(for date: Date) -> CGFloat {
        let minutes = date.timeIntervalSince(dayStart) / 60
        return CGFloat(minutes) * minuteHeight
    }

    private static func markers(from start: Date, to end: Date, calendar: Calendar) -> [String] {
        var markers: [String] = []
        var cursor = start
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        while cursor <= end {
            markers.append(formatter.string(from: cursor))
            guard let next = calendar.date(byAdding: .hour, value: 1, to: cursor) else { break }
            cursor = next
        }
        return markers
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
