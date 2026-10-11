import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnComposeMessageViewModel {
    public var subject = ""
    public var body = ""
    public var recipients: [MessageRecipient] = []
    public var staff: [MessageRecipient] = []
    public var students: [MessageRecipient] = []
    public var staffSearch = ""
    public var studentSearch = ""
    public var blindCopy = false
    public var isLoadingRecipients = false
    public var isSending = false
    public var errorMessage: String?
    public var sentSuccessfully = false
    public var attachments: [MessageComposeAttachment] = []
    public var isUploadingAttachments = false

    private let repository: StudentRepository

    public init(repository: StudentRepository) {
        self.repository = repository
    }

    public var filteredStaff: [MessageRecipient] {
        filterRecipients(staff, query: staffSearch)
    }

    public var filteredStudents: [MessageRecipient] {
        filterRecipients(students, query: studentSearch)
    }

    public func loadRecipients() async {
        guard !isLoadingRecipients else { return }
        isLoadingRecipients = true
        defer { isLoadingRecipients = false }

        async let staffResult = repository.loadMessageRecipients(mode: "staff")
        async let studentsResult = repository.loadMessageRecipients(mode: "student")
        if case .success(let value) = await staffResult {
            staff = value
        }
        if case .success(let value) = await studentsResult {
            students = value
        }
    }

    public func addRecipient(_ recipient: MessageRecipient) {
        guard !recipients.contains(where: { $0.id == recipient.id && $0.isStaff == recipient.isStaff }) else {
            return
        }
        recipients.append(recipient)
    }

    public func removeRecipient(_ recipient: MessageRecipient) {
        recipients.removeAll { $0.id == recipient.id && $0.isStaff == recipient.isStaff }
    }

    public func removeAttachment(_ attachment: MessageComposeAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }

    public func importAttachments(from urls: [URL]) async {
        guard !urls.isEmpty else { return }
        isUploadingAttachments = true
        errorMessage = nil
        defer { isUploadingAttachments = false }

        for url in urls {
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            guard let data = try? Data(contentsOf: url) else {
                errorMessage = "Could not read “\(url.lastPathComponent)”."
                continue
            }
            let filename = url.lastPathComponent
            switch await repository.uploadMessageComposeFile(filename: filename, data: data) {
            case .success(let uploaded):
                if !attachments.contains(where: { $0.id == uploaded.id }) {
                    attachments.append(uploaded)
                }
            case .failure(let error):
                errorMessage = "Upload failed for “\(filename)”: \(error.localizedDescription)"
            }
        }
    }

    public func send() async {
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSubject.isEmpty, !trimmedBody.isEmpty, !recipients.isEmpty else {
            errorMessage = "Subject, message, and at least one recipient are required."
            return
        }

        isSending = true
        errorMessage = nil
        defer { isSending = false }

        let htmlBody = trimmedBody.contains("<")
            ? trimmedBody
            : "<p>\(trimmedBody.split(separator: "\n", omittingEmptySubsequences: false).map { escapeHTML(String($0)) }.joined(separator: "<br>"))</p>"

        switch await repository.sendMessage(
            subject: trimmedSubject,
            contents: htmlBody,
            recipients: recipients,
            blind: blindCopy,
            fileIds: attachments.map(\.id)
        ) {
        case .success:
            attachments = []
            sentSuccessfully = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func filterRecipients(_ list: [MessageRecipient], query: String) -> [MessageRecipient] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return list }
        return list.filter {
            $0.displayName.localizedCaseInsensitiveContains(trimmed)
                || ($0.meta?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    private func escapeHTML(_ line: String) -> String {
        line
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
