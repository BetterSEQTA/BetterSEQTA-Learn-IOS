import CoreDesign
import Domain
import SwiftUI

public struct LearnNoticeDetailView: View {
    public let notice: Notice
    @Environment(\.dismiss) private var dismiss

    public init(notice: Notice) {
        self.notice = notice
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, LearnLayout.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                if !notice.contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LearnHTMLContentView(
                        html: notice.contents,
                        minHeight: 200,
                        allowsInternalScrolling: true
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let preview = notice.contentPreview() {
                    ScrollView {
                        Text(preview)
                            .font(.body)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                            .padding(.horizontal, LearnLayout.horizontalPadding)
                    }
                }
            }
            .background { LearnScreenBackground() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !noticeCopyText.isEmpty {
                        LearnCopyMorphIconButton(
                            text: noticeCopyText,
                            accessibilityLabel: "Copy notice"
                        )
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var noticeCopyText: String {
        let body = notice.plainTextContents.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.isEmpty { return notice.title }
        return "\(notice.title)\n\n\(body)"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = notice.labelTitle {
                Text(label.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LearnTheme.Colors.accent)
            }
            Text(notice.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
            if let staff = notice.staff, !staff.isEmpty {
                Label(staff, systemImage: "person")
                    .font(.subheadline)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .learnGroupedGlass()
    }
}
