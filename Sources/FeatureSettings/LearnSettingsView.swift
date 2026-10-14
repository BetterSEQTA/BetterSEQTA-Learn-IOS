import CoreDesign
import FeatureNotifications
import SwiftUI

public struct LearnSettingsView: View {
    @State private var viewModel: LearnSettingsViewModel
    private let onLogout: () -> Void
    private let onCalendarSyncTap: (() -> Void)?

    public init(
        viewModel: LearnSettingsViewModel,
        onLogout: @escaping () -> Void,
        onCalendarSyncTap: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onLogout = onLogout
        self.onCalendarSyncTap = onCalendarSyncTap
    }

    public var body: some View {
        List {
            Section("Account") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.displayName ?? "Signed in")
                        .font(LearnTypography.rowTitle)
                }
                .listRowBackground(LearnGlassListRowBackground())
                if let host = viewModel.schoolHost, !host.isEmpty {
                    LearnCopyMorphRow(title: "School URL", value: host)
                        .listRowBackground(LearnGlassListRowBackground())
                }
            }

            Section("Preferences") {
                Label("Theme follows system", systemImage: "circle.lefthalf.filled")
                NavigationLink {
                    LearnNotificationsSettingsView()
                } label: {
                    Label("Notifications & sync", systemImage: "bell")
                }
                if let onCalendarSyncTap {
                    Button(action: onCalendarSyncTap) {
                        Label("Calendar sync", systemImage: "calendar.badge.clock")
                    }
                }
            }
            .listRowBackground(LearnGlassListRowBackground())

            Section {
                if viewModel.isLoggingOut {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    LearnInlineDestructiveConfirm(idleTitle: "Log out") {
                        Task {
                            await viewModel.logout()
                            onLogout()
                        }
                    }
                }
            }
            .listRowBackground(LearnGlassListRowBackground())
        }
        .learnInsetSettingsList()
        .learnShellNavigationDepth(0)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.refreshFromSession() }
    }
}
