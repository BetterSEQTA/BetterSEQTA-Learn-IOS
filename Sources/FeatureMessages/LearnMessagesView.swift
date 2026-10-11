import CoreDesign
import Domain
import SwiftUI

public struct LearnMessagesView: View {
    @State private var viewModel: LearnMessagesViewModel
    @State private var selectedMessage: MessageSummary?
    @State private var showCompose = false

    public init(viewModel: LearnMessagesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    LearnScreenHeader(
                        title: "Messages",
                        subtitle: viewModel.unreadCount > 0 ? "\(viewModel.unreadCount) unread" : viewModel.selectedFolder.label
                    )
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .padding(16)
                    }
                    .accessibilityLabel("Compose message")
                }

                Picker("Folder", selection: Binding(
                    get: { viewModel.selectedFolder },
                    set: { viewModel.selectFolder($0) }
                )) {
                    ForEach(MessageFolder.allCases) { folder in
                        Text(folder.label).tag(folder)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                TextField("Search messages", text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .onChange(of: viewModel.searchQuery) { _, _ in
                        viewModel.scheduleSearchReload()
                    }

                Group {
                    if viewModel.isLoading {
                        LearnLoadingState()
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
                            ForEach(viewModel.filteredMessages) { message in
                                Button {
                                    selectedMessage = message
                                } label: {
                                    LearnMessageRow(message: message)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                            }
                            if viewModel.hasMore, viewModel.searchQuery.isEmpty {
                                Button {
                                    Task { await viewModel.loadMore() }
                                } label: {
                                    HStack {
                                        Spacer()
                                        if viewModel.isLoadingMore {
                                            ProgressView()
                                        } else {
                                            Text("Load more")
                                                .font(.subheadline.weight(.medium))
                                        }
                                        Spacer()
                                    }
                                }
                                .disabled(viewModel.isLoadingMore)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { await viewModel.load() }
                    }
                }
            }
            .background(LearnTheme.Colors.background)
            .task { await viewModel.load() }
            .sheet(item: $selectedMessage, onDismiss: {
                Task { await viewModel.load() }
            }) { message in
                LearnMessageDetailView(
                    viewModel: viewModel.detailViewModel(for: message)
                )
            }
            .sheet(isPresented: $showCompose, onDismiss: {
                Task { await viewModel.load() }
            }) {
                LearnComposeMessageView(
                    viewModel: LearnComposeMessageViewModel(repository: viewModel.studentRepository)
                )
            }
        }
    }
}

private struct LearnMessageRow: View {
    let message: MessageSummary

    var body: some View {
        LearnGlassCard {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(message.unread ? Color.accentColor : Color.clear)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.title)
                            .font(.headline)
                            .foregroundStyle(LearnTheme.Colors.primaryText)
                        Spacer(minLength: 4)
                        if message.hasAttachments {
                            Image(systemName: "paperclip")
                                .font(.caption)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                        }
                        if message.starred {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color.yellow)
                        }
                    }
                    if let subtitle = message.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                            .lineLimit(2)
                    }
                    if let timestamp = message.timestamp {
                        Text(timestamp)
                            .font(.caption)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
            }
        }
    }
}

extension MessageSummary: Identifiable {}
