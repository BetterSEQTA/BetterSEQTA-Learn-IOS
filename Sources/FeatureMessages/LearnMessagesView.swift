import CoreDesign
import Domain
import SwiftUI

public struct LearnMessagesView: View {
    @State private var viewModel: LearnMessagesViewModel
    @Binding private var showCompose: Bool

    public init(viewModel: LearnMessagesViewModel, showCompose: Binding<Bool>) {
        _viewModel = State(initialValue: viewModel)
        _showCompose = showCompose
    }

    public var body: some View {
        VStack(spacing: 0) {
            messagesChrome
            messageList
        }
        .background { LearnScreenBackground() }
        .learnShellNavigationDepth(0)
        .navigationDestination(for: MessageSummary.self) { message in
            LearnMessageDetailView(
                viewModel: viewModel.detailViewModel(for: message)
            )
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showCompose, onDismiss: {
            Task { await viewModel.load() }
        }) {
            LearnComposeMessageView(
                viewModel: LearnComposeMessageViewModel(repository: viewModel.studentRepository)
            )
        }
    }

    private var messagesChrome: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                mailSearchField
                if viewModel.unreadCount > 0 {
                    Text("\(viewModel.unreadCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LearnTheme.Colors.accent, in: Capsule())
                        .contentTransition(.numericText())
                        .accessibilityLabel("\(viewModel.unreadCount) unread")
                }
            }
            .padding(.horizontal, LearnLayout.horizontalPadding)
            folderRail
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            LearnSeparatorHairline()
        }
    }

    private var mailSearchField: some View {
        LearnSearchField(text: $viewModel.searchQuery, compact: true, onChange: {
            viewModel.scheduleSearchReload()
        })
        .learnComposeMaterial(cornerRadius: LearnTheme.controlCornerRadius)
    }

    private var folderRail: some View {
        LearnUnderlineSegmentBar(
            items: MessageFolder.allCases.map { ($0, $0.label) },
            selection: viewModel.selectedFolder,
            density: .compact,
            style: .fluid
        ) { folder in
            viewModel.selectFolder(folder)
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
    }

    @ViewBuilder
    private var messageList: some View {
        Group {
            if viewModel.isLoading, viewModel.messages.isEmpty {
                LearnLoadingState(preset: .mailList(rows: 9))
            } else if let error = viewModel.errorMessage, viewModel.messages.isEmpty {
                LearnErrorBanner(message: error) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.filteredMessages.isEmpty {
                LearnEmptyState(
                    title: "No messages",
                    message: "Nothing in \(viewModel.selectedFolder.label.lowercased()) right now."
                )
            } else {
                List {
                    ForEach(Array(viewModel.filteredMessages.enumerated()), id: \.element.id) { index, message in
                        NavigationLink(value: message) {
                            LearnMailRow(message: message)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.visible)
                        .listRowSeparatorTint(LearnTheme.Colors.separator)
                        .listRowBackground(Color.clear)
                        .learnListEntrance(index: index)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await viewModel.load() }
            }
        }
        .id(viewModel.selectedFolder)
        .transition(.opacity.animation(LearnMotion.spatialStandardDefault))
    }
}

private struct LearnMailRow: View {
    let message: MessageSummary

    private var senderLine: String {
        let subtitle = message.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return subtitle.isEmpty ? "SEQTA" : subtitle
    }

    private var previewLine: String {
        message.title
    }

    private var shortDate: String {
        guard let raw = message.timestamp else { return "" }
        if raw.count >= 10 {
            return String(raw.prefix(10))
        }
        return raw
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(senderLine.prefix(1)).uppercased())
                .font(LearnTypography.rowTitle)
                .foregroundStyle(LearnTheme.Colors.accent)
                .frame(width: 34, height: 34)
                .background(LearnTheme.Colors.accent.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(senderLine)
                        .font(message.unread ? LearnTypography.rowTitle : LearnTypography.rowBody.weight(.medium))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(shortDate)
                        .font(LearnTypography.rowMeta)
                        .foregroundStyle(LearnTheme.Colors.tertiaryText)
                        .lineLimit(1)
                }

                Text(previewLine)
                    .font(LearnTypography.rowBody)
                    .foregroundStyle(
                        message.unread
                            ? LearnTheme.Colors.primaryText
                            : LearnTheme.Colors.secondaryText
                    )
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .learnReadableBody()

                if message.hasAttachments || message.starred || message.unread {
                    HStack(spacing: 8) {
                        if message.unread {
                            Text("Unread")
                                .font(LearnTypography.chip)
                                .foregroundStyle(LearnTheme.Colors.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(LearnTheme.Colors.accent.opacity(0.14), in: Capsule())
                        }
                        if message.hasAttachments {
                            Image(systemName: "paperclip")
                                .foregroundStyle(LearnTheme.Colors.tertiaryText)
                        }
                        if message.starred {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.yellow.opacity(0.9))
                        }
                    }
                    .font(LearnTypography.caption)
                }
            }
        }
        .padding(.horizontal, LearnLayout.horizontalPadding)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
