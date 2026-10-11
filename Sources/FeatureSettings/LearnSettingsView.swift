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
                        .font(.headline)
                    Text(viewModel.schoolHost ?? "School account")
                        .font(.subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                .listRowBackground(LearnTheme.Colors.card)
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
            .listRowBackground(LearnTheme.Colors.card)

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
            .listRowBackground(LearnTheme.Colors.card)
        }
        .scrollContentBackground(.hidden)
        .background(LearnTheme.Colors.background)
        .navigationTitle("Settings")
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
