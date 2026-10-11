import SwiftUI

public enum LearnSkeletonPreset: Sendable {
    case list(rows: Int)
    case mailList(rows: Int)
    case noticeList(rows: Int)
    case assessmentList(rows: Int)
    case portalGrid(cells: Int)
    case timetableDay
    case detailBody
    case settingsForm
}

public struct LearnShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    public func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.55)
                        .offset(x: animate ? geo.size.width : -geo.size.width)
                    }
                    .clipped()
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}

extension View {
    public func learnShimmer() -> some View {
        modifier(LearnShimmerModifier())
    }
}

public struct LearnSkeletonBlock: View {
    private let height: CGFloat
    private let width: CGFloat?

    public init(height: CGFloat, width: CGFloat? = nil) {
        self.height = height
        self.width = width
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(LearnTheme.Colors.card.opacity(0.65))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : width, alignment: .leading)
            .learnShimmer()
    }
}

public struct LearnSkeletonView: View {
    private let preset: LearnSkeletonPreset

    public init(preset: LearnSkeletonPreset) {
        self.preset = preset
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch preset {
                case .list(let rows):
                    listSkeleton(rows: rows, style: .generic)
                case .mailList(let rows):
                    listSkeleton(rows: rows, style: .mail)
                case .noticeList(let rows):
                    listSkeleton(rows: rows, style: .notice)
                case .assessmentList(let rows):
                    listSkeleton(rows: rows, style: .assessment)
                case .portalGrid(let cells):
                    portalGridSkeleton(cells: cells)
                case .timetableDay:
                    timetableSkeleton
                case .detailBody:
                    detailSkeleton
                case .settingsForm:
                    settingsSkeleton
                }
            }
            .padding(.vertical, 8)
        }
        .scrollDisabled(true)
    }

    private enum RowStyle { case generic, mail, notice, assessment }

    private func listSkeleton(rows: Int, style: RowStyle) -> some View {
        ForEach(0 ..< rows, id: \.self) { index in
            row(for: style)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .learnStaggeredAppear(index: index, baseDelay: 0.03)
            if index < rows - 1 {
                Divider().padding(.leading, style == .mail ? 72 : 20)
            }
        }
    }

    @ViewBuilder
    private func row(for style: RowStyle) -> some View {
        switch style {
        case .generic:
            VStack(alignment: .leading, spacing: 8) {
                LearnSkeletonBlock(height: 14, width: 120)
                LearnSkeletonBlock(height: 12)
            }
        case .mail:
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(LearnTheme.Colors.card.opacity(0.65))
                    .frame(width: 40, height: 40)
                    .learnShimmer()
                VStack(alignment: .leading, spacing: 8) {
                    LearnSkeletonBlock(height: 14)
                    LearnSkeletonBlock(height: 12, width: 200)
                }
            }
        case .notice:
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(LearnTheme.Colors.card.opacity(0.65)).frame(width: 8, height: 8).learnShimmer()
                VStack(alignment: .leading, spacing: 8) {
                    LearnSkeletonBlock(height: 14)
                    LearnSkeletonBlock(height: 12, width: 180)
                }
            }
        case .assessment:
            HStack(spacing: 12) {
                LearnSkeletonBlock(height: 48, width: 4)
                VStack(alignment: .leading, spacing: 8) {
                    LearnSkeletonBlock(height: 12, width: 80)
                    LearnSkeletonBlock(height: 14)
                    LearnSkeletonBlock(height: 10, width: 100)
                }
            }
        }
    }

    private func portalGridSkeleton(cells: Int) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 12)], spacing: 12) {
            ForEach(0 ..< cells, id: \.self) { index in
                RoundedRectangle(cornerRadius: LearnTheme.cardCornerRadius, style: .continuous)
                    .fill(LearnTheme.Colors.card.opacity(0.55))
                    .frame(height: 100)
                    .learnShimmer()
                    .learnStaggeredAppear(index: index)
            }
        }
        .padding(20)
    }

    private var timetableSkeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            LearnSkeletonBlock(height: 88)
            ForEach(0 ..< 4, id: \.self) { index in
                HStack(alignment: .top, spacing: 14) {
                    Circle()
                        .fill(LearnTheme.Colors.card.opacity(0.65))
                        .frame(width: 12, height: 12)
                        .learnShimmer()
                    LearnSkeletonBlock(height: 76)
                }
                .learnStaggeredAppear(index: index)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var detailSkeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            LearnSkeletonBlock(height: 22, width: 240)
            LearnSkeletonBlock(height: 14, width: 160)
            LearnSkeletonBlock(height: 120)
            LearnSkeletonBlock(height: 200)
        }
        .padding(20)
    }

    private var settingsSkeleton: some View {
        VStack(spacing: 12) {
            ForEach(0 ..< 5, id: \.self) { index in
                LearnSkeletonBlock(height: 44)
                    .learnStaggeredAppear(index: index)
            }
        }
        .padding(20)
    }
}
