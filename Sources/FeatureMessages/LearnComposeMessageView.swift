import CoreDesign
import Domain
import SwiftUI
import UniformTypeIdentifiers

/// Mail-style compose (layout inspired by [BetterSEQTA Teach iOS](https://github.com/BetterSEQTA/BetterSEQTA-Teach-IOS)).
public struct LearnComposeMessageView: View {
    @State private var viewModel: LearnComposeMessageViewModel
    @State private var showFileImporter = false
    @State private var showRecipientPicker = false
    @State private var toSearchText = ""
    @FocusState private var toFieldFocused: Bool
    @FocusState private var subjectFocused: Bool
    @FocusState private var bodyFocused: Bool
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: LearnComposeMessageViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                recipientSection
                LearnSeparatorHairline()
                subjectRow
                LearnSeparatorHairline()
                messageEditor
                attachmentBar
            }
            .background { LearnScreenBackground() }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    LearnMorphingIconButton(
                        systemImage: "paperplane.fill",
                        successImage: "checkmark.circle.fill",
                        accessibilityLabel: "Send message"
                    ) {
                        guard !viewModel.recipients.isEmpty else { return false }
                        await viewModel.send()
                        if viewModel.sentSuccessfully {
                            dismiss()
                            return true
                        }
                        return false
                    }
                    .disabled(viewModel.isSending || viewModel.recipients.isEmpty)
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
            .sheet(isPresented: $showRecipientPicker) {
                LearnComposeRecipientPickerSheet(viewModel: viewModel)
            }
            .overlay {
                if viewModel.isLoadingRecipients {
                    composeLoadingOverlay
                }
            }
            .animation(LearnMotion.spatialStandardDefault, value: viewModel.recipients.count)
        }
        .presentationDragIndicator(.visible)
    }

    private var composeLoadingOverlay: some View {
        VStack {
            FluidLoadingBarView(progress: 0.35, phaseText: "Loading contacts…")
                .padding(.horizontal, 32)
                .padding(.top, 120)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LearnTheme.Colors.background.opacity(0.92))
    }

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Text("To:")
                    .font(.subheadline)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
                    .padding(.top, 8)

                ComposeRecipientFlowLayout(spacing: 6) {
                    ForEach(viewModel.recipients) { recipient in
                        recipientTag(recipient)
                    }
                    TextField("Add recipient…", text: $toSearchText)
                        .font(.subheadline)
                        .focused($toFieldFocused)
                        .frame(minWidth: 100)
                        .onSubmit { addFirstSuggestionIfPossible() }
                }

                Button {
                    showRecipientPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(LearnTheme.Colors.accent)
                }
                .padding(.top, 4)
                .learnPressFeedback(scale: 0.92)
            }
            .padding(.horizontal, LearnLayout.horizontalPadding)
            .padding(.vertical, 12)

            if toFieldFocused, !toAutocomplete.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(toAutocomplete.prefix(5))) { recipient in
                        Button {
                            viewModel.addRecipient(recipient)
                            toSearchText = ""
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipient.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(LearnTheme.Colors.primaryText)
                                    if let meta = recipient.meta {
                                        Text(meta)
                                            .font(.caption)
                                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, LearnLayout.horizontalPadding)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        LearnSeparatorHairline()
                    }
                }
                .learnComposeMaterial(cornerRadius: 0)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Toggle("BCC (hide recipients)", isOn: $viewModel.blindCopy)
                .font(.subheadline)
                .padding(.horizontal, LearnLayout.horizontalPadding)
                .padding(.vertical, 10)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, LearnLayout.horizontalPadding)
                    .padding(.bottom, 8)
            }
        }
    }

    private var toAutocomplete: [MessageRecipient] {
        viewModel.autocompleteRecipients(query: toSearchText, excluding: viewModel.recipients)
    }

    private func addFirstSuggestionIfPossible() {
        guard let first = toAutocomplete.first else { return }
        viewModel.addRecipient(first)
        toSearchText = ""
    }

    private func recipientTag(_ recipient: MessageRecipient) -> some View {
        HStack(spacing: 4) {
            Text(recipient.displayName)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            Button {
                viewModel.removeRecipient(recipient)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            LearnTheme.Colors.groupedFill,
            in: RoundedRectangle(cornerRadius: 4, style: .continuous)
        )
    }

    private var subjectRow: some View {
        HStack(spacing: 8) {
            Text("Subject:")
                .font(.subheadline)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            TextField("Subject", text: $viewModel.subject)
                .font(.body)
                .focused($subjectFocused)
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .padding(.vertical, 12)
    }

    private var messageEditor: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.body.isEmpty, !bodyFocused {
                Text("Write your message…")
                    .font(.body)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
                    .padding(.horizontal, LearnLayout.horizontalPadding + 4)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $viewModel.body)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, LearnLayout.horizontalPadding - 4)
                .padding(.vertical, 8)
                .focused($bodyFocused)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var attachmentBar: some View {
        VStack(spacing: 0) {
            LearnSeparatorHairline()
            HStack {
                Button {
                    showFileImporter = true
                } label: {
                    Label("Attach", systemImage: "paperclip")
                        .font(.subheadline.weight(.medium))
                }
                .disabled(viewModel.isUploadingAttachments || viewModel.isSending)
                Spacer()
                if viewModel.isUploadingAttachments {
                    ProgressView()
                        .controlSize(.small)
                } else if !viewModel.attachments.isEmpty {
                    Text("\(viewModel.attachments.count) file\(viewModel.attachments.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
            .padding(.horizontal, LearnLayout.horizontalPadding)
            .padding(.vertical, 12)
            .learnComposeMaterial(cornerRadius: 0)

            if !viewModel.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.attachments) { file in
                            HStack(spacing: 6) {
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(LearnTheme.Colors.accent)
                                Text(file.filename)
                                    .font(.caption)
                                    .lineLimit(1)
                                Button {
                                    viewModel.removeAttachment(file)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2.weight(.bold))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .learnComposeMaterial(cornerRadius: 6)
                        }
                    }
                    .padding(.horizontal, LearnLayout.horizontalPadding)
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

// MARK: - Recipient picker sheet

private struct LearnComposeRecipientPickerSheet: View {
    @Bindable var viewModel: LearnComposeMessageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Staff") {
                    ForEach(filteredStaff) { recipient in
                        recipientRow(recipient)
                    }
                }
                Section("Students") {
                    ForEach(filteredStudents) { recipient in
                        recipientRow(recipient)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: "Search people")
            .navigationTitle("Recipients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var filteredStaff: [MessageRecipient] {
        viewModel.filteredStaff.filter { r in
            query.isEmpty || r.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredStudents: [MessageRecipient] {
        viewModel.filteredStudents.filter { r in
            query.isEmpty || r.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    private func recipientRow(_ recipient: MessageRecipient) -> some View {
        let selected = viewModel.recipients.contains(where: {
            $0.id == recipient.id && $0.isStaff == recipient.isStaff
        })
        return Button {
            if selected {
                viewModel.removeRecipient(recipient)
            } else {
                viewModel.addRecipient(recipient)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipient.displayName)
                    if let meta = recipient.meta {
                        Text(meta)
                            .font(.caption)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? LearnTheme.Colors.accent : LearnTheme.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Flow layout (Teach-style To: row)

private struct ComposeRecipientFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
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

    private func arrange(proposal: ProposedViewSize, subviews: Subviews)
        -> (size: CGSize, placements: [(index: Int, x: CGFloat, y: CGFloat)]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var placements: [(Int, CGFloat, CGFloat)] = []

        for index in subviews.indices {
            let isLast = index == subviews.count - 1
            let size = subviews[index].sizeThatFits(.unspecified)
            let itemWidth = isLast ? max(size.width, max(0, maxWidth - x)) : size.width

            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            placements.append((index, x, y))
            rowHeight = max(rowHeight, size.height)
            x += itemWidth + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), placements)
    }
}
