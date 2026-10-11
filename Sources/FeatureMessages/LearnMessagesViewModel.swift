import CoreSession
import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnMessagesViewModel {
    public static let pageSize = 50

    public var messages: [MessageSummary] = []
    public var selectedFolder: MessageFolder = .inbox
    public var searchQuery = ""
    public var isLoading = false
    public var isLoadingMore = false
    public var hasMore = false
    public var errorMessage: String?

    private var listOffset = 0
    private var searchReloadTask: Task<Void, Never>?
    private let repository: StudentRepository

    public var studentRepository: StudentRepository { repository }

    public init(repository: StudentRepository) {
        self.repository = repository
    }

    public var filteredMessages: [MessageSummary] { messages }

    public var unreadCount: Int {
        messages.filter(\.unread).count
    }

    public func selectFolder(_ folder: MessageFolder) {
        guard selectedFolder != folder else { return }
        selectedFolder = folder
        messages = []
        hasMore = false
        errorMessage = nil
        Task { await load() }
    }

    public func scheduleSearchReload() {
        searchReloadTask?.cancel()
        searchReloadTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await load()
        }
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        listOffset = 0
        defer { isLoading = false }

        switch await repository.getMessages(
            folder: selectedFolder,
            searchValue: searchQuery,
            offset: 0,
            limit: Self.pageSize
        ) {
        case .success(let value):
            messages = value
            listOffset = value.count
            hasMore = value.count >= Self.pageSize
        case .failure(let error):
            errorMessage = error.localizedDescription
            messages = []
            hasMore = false
        }
    }

    public func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        switch await repository.getMessages(
            folder: selectedFolder,
            searchValue: searchQuery,
            offset: listOffset,
            limit: Self.pageSize
        ) {
        case .success(let value):
            messages.append(contentsOf: value)
            listOffset += value.count
            hasMore = value.count >= Self.pageSize
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    public func markReadLocally(id: Int) {
        messages = messages.map { message in
            guard message.id == id else { return message }
            return MessageSummary(
                id: message.id,
                title: message.title,
                subtitle: message.subtitle,
                timestamp: message.timestamp,
                unread: false,
                starred: message.starred,
                hasAttachments: message.hasAttachments
            )
        }
        LearnInboxDidChangeNotifier.post()
    }

    public func removeMessageLocally(id: Int) {
        messages = messages.filter { $0.id != id }
    }

    public func applyStarState(id: Int, starred: Bool) {
        if selectedFolder == .starred, !starred {
            removeMessageLocally(id: id)
            return
        }
        messages = messages.map { message in
            guard message.id == id else { return message }
            return MessageSummary(
                id: message.id,
                title: message.title,
                subtitle: message.subtitle,
                timestamp: message.timestamp,
                unread: message.unread,
                starred: starred,
                hasAttachments: message.hasAttachments
            )
        }
    }

    public func detailViewModel(for summary: MessageSummary) -> LearnMessageDetailViewModel {
        let model = LearnMessageDetailViewModel(
            summary: summary,
            folder: selectedFolder,
            repository: repository
        )
        model.onRead = { [weak self] id in
            self?.markReadLocally(id: id)
        }
        model.onRemoved = { [weak self] id in
            self?.removeMessageLocally(id: id)
        }
        model.onStarChanged = { [weak self] id, starred in
            self?.applyStarState(id: id, starred: starred)
        }
        return model
    }
}
