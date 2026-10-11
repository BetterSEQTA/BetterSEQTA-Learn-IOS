import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnMessageDetailViewModel {
    public let summary: MessageSummary
    public let folder: MessageFolder

    public var htmlBody: String?
    public var attachments: [MessageAttachment] = []
    public var isLoading = false
    public var isStarred = false
    public var isUpdatingStar = false
    public var isMoving = false
    public var downloadingAttachmentUUID: String?
    public var errorMessage: String?
    public var attachmentErrorMessage: String?

    private let repository: StudentRepository
    public var onRead: ((Int) -> Void)?
    public var onRemoved: ((Int) -> Void)?
    public var onStarChanged: ((Int, Bool) -> Void)?

    public init(summary: MessageSummary, folder: MessageFolder, repository: StudentRepository) {
        self.summary = summary
        self.folder = folder
        self.repository = repository
        self.isStarred = summary.starred
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch await repository.getMessageDetail(id: summary.id) {
        case .success(let detail):
            htmlBody = detail.htmlBody
            attachments = detail.attachments
            isStarred = detail.starred
            if !detail.read {
                _ = await repository.setMessagesRead(ids: [summary.id], read: true)
                onRead?(summary.id)
            } else if summary.unread {
                onRead?(summary.id)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    public func toggleStar() async {
        guard !isUpdatingStar else { return }
        isUpdatingStar = true
        defer { isUpdatingStar = false }

        let next = !isStarred
        switch await repository.setMessagesStarred(ids: [summary.id], starred: next) {
        case .success:
            isStarred = next
            onStarChanged?(summary.id, next)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    public func moveToTrash() async -> Bool {
        await moveToLabel("trash")
    }

    public func restoreToInbox() async -> Bool {
        await moveToLabel(MessageFolder.inbox.apiLabel)
    }

    public func deleteFromTrash() async -> Bool {
        await moveToLabel("trash")
    }

    public func openAttachment(_ attachment: MessageAttachment) async {
        guard downloadingAttachmentUUID == nil else { return }
        downloadingAttachmentUUID = attachment.uuid
        attachmentErrorMessage = nil
        defer { downloadingAttachmentUUID = nil }

        switch await repository.downloadMessageAttachment(uuid: attachment.uuid) {
        case .success(let data):
            let opened = LearnMessageAttachmentPresenter.present(
                data: data,
                filename: attachment.filename,
                mimetype: attachment.mimetype
            )
            if !opened {
                attachmentErrorMessage = "Could not open attachment"
            }
        case .failure:
            attachmentErrorMessage = "Could not download attachment"
        }
    }

    public func clearAttachmentError() {
        attachmentErrorMessage = nil
    }

    private func moveToLabel(_ label: String) async -> Bool {
        guard !isMoving else { return false }
        isMoving = true
        defer { isMoving = false }

        switch await repository.moveMessagesToLabel(ids: [summary.id], label: label) {
        case .success:
            onRemoved?(summary.id)
            return true
        case .failure(let error):
            errorMessage = error.localizedDescription
            return false
        }
    }
}
