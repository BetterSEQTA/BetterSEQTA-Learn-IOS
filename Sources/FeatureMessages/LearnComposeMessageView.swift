import CoreDesign
import Domain
import SwiftUI
import UniformTypeIdentifiers

public struct LearnComposeMessageView: View {
    @State private var viewModel: LearnComposeMessageViewModel
    @State private var showFileImporter = false
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: LearnComposeMessageViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let error = viewModel.errorMessage {
                        LearnErrorBanner(message: error) {
                            viewModel.errorMessage = nil
                        }
                    }

                    recipientChips

                    TextField("Subject", text: $viewModel.subject)
                        .textFieldStyle(.roundedBorder)

                    TextField("Message", text: $viewModel.body, axis: .vertical)
                        .lineLimit(5...12)
                        .textFieldStyle(.roundedBorder)

                    Toggle("Blind copy (BCC)", isOn: $viewModel.blindCopy)

                    attachmentsSection

                    recipientPicker(title: "Staff", query: $viewModel.staffSearch, recipients: viewModel.filteredStaff)
                    recipientPicker(title: "Students", query: $viewModel.studentSearch, recipients: viewModel.filteredStudents)
                }
                .padding(16)
            }
            .background(LearnTheme.Colors.background)
            .navigationTitle("New message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSending {
                        ProgressView()
                    } else {
                        Button("Send") {
                            Task {
                                await viewModel.send()
                                if viewModel.sentSuccessfully {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .task { await viewModel.loadRecipients() }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    Task { await viewModel.importAttachments(from: urls) }
                case .failure:
                    viewModel.errorMessage = "Could not open the selected file."
                }
            }
            .overlay {
                if viewModel.isLoadingRecipients || viewModel.isUploadingAttachments {
                    LearnLoadingState()
                }
            }
        }
    }

    @ViewBuilder
    private var attachmentsSection: some View {
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Attachments")
                        .font(.headline)
                    Spacer()
                    Button("Add files") { showFileImporter = true }
                        .font(.subheadline.weight(.semibold))
                        .disabled(viewModel.isUploadingAttachments || viewModel.isSending)
                }
                if viewModel.attachments.isEmpty {
                    Text("Optional — files upload before send.")
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                } else {
                    ForEach(viewModel.attachments) { file in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                            Text(file.filename)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                viewModel.removeAttachment(file)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recipientChips: some View {
        if viewModel.recipients.isEmpty {
            Text("Add at least one recipient below.")
                .font(.caption)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
        } else {
            FlowLayout(spacing: 8) {
                ForEach(viewModel.recipients) { recipient in
                    HStack(spacing: 4) {
                        Text(recipient.displayName)
                            .font(.caption)
                        Button {
                            viewModel.removeRecipient(recipient)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(LearnTheme.Colors.card, in: Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private func recipientPicker(
        title: String,
        query: Binding<String>,
        recipients: [MessageRecipient]
    ) -> some View {
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                TextField("Search \(title.lowercased())", text: query)
                    .textFieldStyle(.roundedBorder)
                ForEach(recipients.prefix(8)) { recipient in
                    Button {
                        viewModel.addRecipient(recipient)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recipient.displayName)
                                    .foregroundStyle(LearnTheme.Colors.primaryText)
                                if let meta = recipient.meta {
                                    Text(meta)
                                        .font(.caption)
                                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                                }
                            }
                            Spacer()
                            Image(systemName: "plus.circle")
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Simple horizontal wrapping layout for recipient chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for placement in result.placements {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.x, y: bounds.minY + placement.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, placements: [(index: Int, x: CGFloat, y: CGFloat)]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var placements: [(Int, CGFloat, CGFloat)] = []

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            placements.append((index, x, y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), placements)
    }
}
