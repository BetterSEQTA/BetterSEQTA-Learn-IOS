import CoreDesign
import Domain
import SwiftUI

/// Student submission files (DesQTA `AssessmentSubmissions.svelte` — view/download).
struct LearnAssessmentSubmissionsSection: View {
    let files: [AssessmentSubmissionFile]
    let downloadingUUID: String?
    let errorMessage: String?
    let onDownload: (AssessmentSubmissionFile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorMessage {
                LearnErrorBanner(message: errorMessage) {}
            }

            if files.isEmpty {
                LearnEmptyState(
                    title: "No submissions yet",
                    message: "You have not uploaded any files for this assessment. Use SEQTA Learn on the web to add files if online submission is enabled."
                )
            } else {
                ForEach(files) { file in
                    submissionRow(file)
                }
            }
        }
    }

    private func submissionRow(_ file: AssessmentSubmissionFile) -> some View {
        let isLoading = file.uuid != nil && downloadingUUID == file.uuid
        return Button {
            LearnHaptics.lightImpact()
            onDownload(file)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconName(for: file.mimeType))
                    .font(.title3)
                    .foregroundStyle(LearnTheme.Colors.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.filename)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        if let size = formattedSize(file.sizeBytes) {
                            Text(size)
                        }
                        if let created = file.createdDate {
                            Text(created)
                        }
                        Text(file.isStaff ? "Teacher" : "You")
                    }
                    .font(.caption)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                Spacer(minLength: 0)
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(LearnTheme.Colors.accent)
                }
            }
            .padding(14)
            .learnGroupedGlass(cornerRadius: 12)
        }
        .buttonStyle(LearnPressFeedbackStyle(scale: 0.99))
        .disabled(file.uuid == nil || downloadingUUID != nil)
    }

    private func iconName(for mimeType: String) -> String {
        if mimeType.hasPrefix("video/") { return "video.fill" }
        if mimeType.contains("presentation") { return "rectangle.on.rectangle.angled" }
        if mimeType.hasPrefix("image/") { return "photo.fill" }
        return "doc.fill"
    }

    private func formattedSize(_ bytes: Int?) -> String? {
        guard let bytes else { return nil }
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
