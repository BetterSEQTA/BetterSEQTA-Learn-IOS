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
        NavigationStack {
            Group {
                if viewModel.isLoading, viewModel.htmlBody == nil {
                    LearnLoadingState()
                } else if let error = viewModel.errorMessage, viewModel.htmlBody == nil {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if let html = viewModel.htmlBody {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(viewModel.summary.title)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(LearnTheme.Colors.primaryText)
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
                                            Task { await viewModel.openAttachment(file) }
                                        } label: {
                                            LearnMessageAttachmentRow(
                                                file: file,
                                                isLoading: viewModel.downloadingAttachmentUUID == file.uuid
                                            )
                                        }
                                        .buttonStyle(.plain)
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
            .background(LearnTheme.Colors.background)
            .navigationTitle("Message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if viewModel.folder == .trash {
                        Button {
                            Task {
                                if await viewModel.restoreToInbox() { dismiss() }
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(viewModel.isMoving)
                        .accessibilityLabel("Restore to inbox")
                        Button(role: .destructive) {
                            Task {
                                if await viewModel.deleteFromTrash() { dismiss() }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(viewModel.isMoving)
                        .accessibilityLabel("Delete message")
                    } else {
                        Button {
                            Task { await viewModel.toggleStar() }
                        } label: {
                            Image(systemName: viewModel.isStarred ? "star.fill" : "star")
                        }
                        .disabled(viewModel.isUpdatingStar)
                        .accessibilityLabel(viewModel.isStarred ? "Unstar message" : "Star message")
                        Button(role: .destructive) {
                            Task {
                                if await viewModel.moveToTrash() { dismiss() }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(viewModel.isMoving)
                        .accessibilityLabel("Move to trash")
                    }
                }
            }
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
    }
}

private struct LearnMessageAttachmentRow: View {
    let file: MessageAttachment
    let isLoading: Bool

    var body: some View {
        LearnGlassCard {
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
                }
            }
        }
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
