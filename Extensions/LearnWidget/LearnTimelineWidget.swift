import CoreDesign
import Domain
import SwiftUI
import WidgetKit

public struct LearnTimelineEntry: TimelineEntry {
    public let date: Date
    public let snapshot: LearnNextLessonSnapshot

    public init(date: Date, snapshot: LearnNextLessonSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

public struct LearnTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> LearnTimelineEntry {
        LearnTimelineEntry(date: .now, snapshot: .placeholder)
    }

    public func getSnapshot(in context: Context, completion: @escaping (LearnTimelineEntry) -> Void) {
        let snapshot: LearnNextLessonSnapshot = {
            if context.isPreview { return .placeholder }
            return LearnWidgetSharedStore.load() ?? .noLessons
        }()
        completion(LearnTimelineEntry(date: .now, snapshot: snapshot))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LearnTimelineEntry>) -> Void) {
        let snapshot = LearnWidgetSharedStore.load() ?? .signedOut
        let entry = LearnTimelineEntry(date: .now, snapshot: snapshot)
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

public struct LearnTimelineWidgetView: View {
    public let entry: LearnTimelineEntry

    public init(entry: LearnTimelineEntry) {
        self.entry = entry
    }

    public var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(LearnTheme.Colors.accent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT LESSON")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.8)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)

                Text(entry.snapshot.subjectName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .lineLimit(1)

                if !entry.snapshot.metaLine.isEmpty {
                    Text(entry.snapshot.metaLine)
                        .font(.system(size: 11))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            LearnTheme.Colors.background
        }
    }
}

public struct LearnTimelineWidget: Widget {
    public let kind = "LearnTimelineWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LearnTimelineProvider()) { entry in
            LearnTimelineWidgetView(entry: entry)
        }
        .configurationDisplayName("Next lesson")
        .description("Shows your next SEQTA timetable lesson.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
