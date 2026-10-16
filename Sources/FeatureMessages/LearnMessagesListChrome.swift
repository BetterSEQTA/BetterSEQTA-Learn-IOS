import CoreDesign
import Domain
import SwiftUI

/// Search + folder rail for Messages — lives in the shell under the top bar (not inside the navigation stack).
public struct LearnMessagesListChrome: View {
    @Bindable var viewModel: LearnMessagesViewModel

    public init(viewModel: LearnMessagesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                LearnSearchField(text: $viewModel.searchQuery, compact: true, onChange: {
                    viewModel.scheduleSearchReload()
                })
                .learnComposeMaterial(cornerRadius: LearnTheme.controlCornerRadius)

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
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .learnShellHeaderBackground()
        .overlay(alignment: .bottom) {
            LearnSeparatorHairline()
        }
    }
}
