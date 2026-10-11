import CoreDesign
import SwiftUI

/// QR tab entry: paste deeplink today; live camera scan wires in when AVFoundation is enabled.
public struct QRScannerEntryView: View {
    @Binding private var pastedLink: String
    private let isLoggingIn: Bool
    private let onSubmitLink: () -> Void
    private let onScannedLink: (String) -> Void

    public init(
        pastedLink: Binding<String>,
        isLoggingIn: Bool,
        onSubmitLink: @escaping () -> Void,
        onScannedLink: @escaping (String) -> Void
    ) {
        self._pastedLink = pastedLink
        self.isLoggingIn = isLoggingIn
        self.onSubmitLink = onSubmitLink
        self.onScannedLink = onScannedLink
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LearnTheme.Spacing.md) {
            Text("Scan your SEQTA QR code")
                .font(.headline)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text("Open SEQTA on another device, or use the QR from your welcome email. BetterSEQTA+ connect QRs work too.")
                .font(.footnote)
                .foregroundStyle(LearnTheme.Colors.secondaryText)

            LearnGlassCard {
                LearnQRCodeScannerView { link in
                    pastedLink = link
                    onScannedLink(link)
                }
            }

            Text("Or paste a link")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            TextField("seqtalearn://sso/…", text: $pastedLink, axis: .vertical)
                .lineLimit(2 ... 4)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(LearnTheme.Spacing.md)
                .learnGlassInsetField()
                .foregroundStyle(LearnTheme.Colors.primaryText)

            Button("Continue with link", action: onSubmitLink)
                .buttonStyle(LearnPrimaryButtonStyle())
                .disabled(pastedLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoggingIn)
        }
    }
}
