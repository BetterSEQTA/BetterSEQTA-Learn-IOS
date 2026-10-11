import CoreDesign
import SwiftUI

public struct UrlEntryView: View {
    private let title: String
    private let placeholder: String
    @Binding private var text: String

    public init(title: String, placeholder: String = "school.seqta.com.au", text: Binding<String>) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LearnTheme.Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.URL)
                .keyboardType(.URL)
                .submitLabel(.continue)
                .padding(LearnTheme.Spacing.md)
                .background(LearnTheme.Colors.card, in: RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius))
                .foregroundStyle(LearnTheme.Colors.primaryText)
        }
    }
}
