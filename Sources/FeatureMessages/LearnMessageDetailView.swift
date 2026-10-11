import CoreDesign
import Domain
import SwiftUI

public struct LearnMessageDetailView: View {
    @State private var viewModel: LearnMessageDetailViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: LearnMessageDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            LearnInlineNavBar(title: viewModel.summary.title) {
                HStack(spacing: 2) {
                    LearnCopyMorphIconButton(
                        text: viewModel.summary.title,
                        accessibilityLabel: "Copy message subject"
                    )
                    messageActions
                }
            }
            Group {
                if viewModel.isLoading, viewModel.htmlBody == nil {
                    LearnLoadingState(preset: .detailBody)
                } else if let error = viewModel.errorMessage, viewModel.htmlBody == nil {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if let html = viewModel.htmlBody {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if let subtitle = viewModel.summary.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(LearnTheme.Colors.secondaryText)
                            }
                            if !viewModel.attachments.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Attachments")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(LearnTheme.Colors.primaryText)
                                    ForEach(viewModel.attachments) { file in
                                        Button {
                                            LearnHaptics.lightImpact()
                                            Task { await viewModel.openAttachment(file) }
                                        } label: {
                                            LearnMessageAttachmentRow(
                                                file: file,
                                                isLoading: viewModel.downloadingAttachmentUUID == file.uuid
                                            )
                                        }
                                        .buttonStyle(LearnPressFeedbackStyle(scale: 0.98))
                                        .disabled(viewModel.downloadingAttachmentUUID != nil)
                                    }
                                }
                            }
                            LearnMessageHTMLWebView(html: html)
                                .frame(minHeight: 200)
                        }
                        .padding()
                    }
                }
            }
            .animation(nil, value: viewModel.isLoading)
        }
        .background { LearnScreenBackground() }
        .learnShellNavigationDepth(1)
        .toolbar(.hidden, for: .navigationBar)
            .alert(
                "Couldn't open attachment",
                isPresented: Binding(
                    get: { viewModel.attachmentErrorMessage != nil },
                    set: { if !$0 { viewModel.clearAttachmentError() } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.clearAttachmentError() }
            } message: {
                Text(viewModel.attachmentErrorMessage ?? "")
            }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var messageActions: some View {
        HStack(spacing: 4) {
            if viewModel.folder == .trash {
                LearnMorphingActionIconButton(
                    idleImage: "arrow.uturn.backward",
                    accessibilityLabel: "Restore to inbox"
                ) {
                    if await viewModel.restoreToInbox() {
                        dismiss()
                        return true
                    }
                    return false
                }
                .disabled(viewModel.isMoving)
                LearnInlineDeleteConfirm(label: "Delete message") {
                    Task {
                        if await viewModel.deleteFromTrash() { dismiss() }
                    }
                }
                .disabled(viewModel.isMoving)
            } else {
                LearnMorphingActionIconButton(
                    idleImage: viewModel.isStarred ? "star.fill" : "star",
                    successImage: "checkmark.circle.fill",
                    tint: Color.yellow.opacity(0.95),
                    accessibilityLabel: viewModel.isStarred ? "Unstar message" : "Star message"
                ) {
                    await viewModel.toggleStar()
                    return true
                }
                .disabled(viewModel.isUpdatingStar)
                LearnInlineDeleteConfirm(label: "Move to trash") {
                    Task {
                        if await viewModel.moveToTrash() { dismiss() }
                    }
                }
                .disabled(viewModel.isMoving)
            }
        }
    }
}

private struct LearnMessageAttachmentRow: View {
    let file: MessageAttachment
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "paperclip")
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.filename)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .lineLimit(2)
                Text(LearnMessageAttachmentFormatting.sizeLabel(file.size))
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
        .padding(14)
        .background(
            LearnTheme.Colors.card.opacity(0.55),
            in: RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius, style: .continuous)
        )
    }
}

enum LearnMessageAttachmentFormatting {
    static func sizeLabel(_ raw: String) -> String {
        guard let bytes = Int(raw) else { return raw }
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
