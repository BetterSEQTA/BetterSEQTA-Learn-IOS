import CoreDesign
import FeatureNotifications
import SwiftUI

public struct LearnSettingsView: View {
    @State private var viewModel: LearnSettingsViewModel
    @State private var showLogoutConfirm = false
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
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    if viewModel.isLoggingOut {
                        ProgressView()
                    } else {
                        Text("Log out")
                    }
                }
                .disabled(viewModel.isLoggingOut)
            }
            .listRowBackground(LearnGlassListRowBackground())
        }
        .learnInsetSettingsList()
        .learnShellNavigationDepth(0)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Log out of BetterSEQTA Learn?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) {
                Task {
                    await viewModel.logout()
                    onLogout()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { viewModel.refreshFromSession() }
    }
}
