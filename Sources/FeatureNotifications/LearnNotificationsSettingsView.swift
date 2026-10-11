import CoreDesign
import SwiftUI
import UIKit

public struct LearnNotificationsSettingsView: View {
    @State private var viewModel: LearnNotificationsSettingsViewModel
    @Environment(\.openURL) private var openURL

    public init(viewModel: LearnNotificationsSettingsViewModel = LearnNotificationsSettingsViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            if let hint = viewModel.systemSettingsHint {
                Section {
                    Text(hint)
                        .font(.subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    if viewModel.authorizationStatus == .denied {
                        Button("Open iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                    }
                }
                .listRowBackground(LearnGlassListRowBackground())
            }

            Section("Notifications & sync") {
                Toggle(isOn: assessmentBinding) {
                    notificationRow(
                        title: "Assessment reminders",
                        subtitle: "3-day, 1-day, due date, and overdue alerts"
                    )
                }
                .disabled(viewModel.isRequestingPermission)

                Toggle(isOn: noticeBinding) {
                    notificationRow(
                        title: "New notices",
                        subtitle: "Alert when SEQTA publishes notices for today"
                    )
                }
                .disabled(viewModel.isRequestingPermission)

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Timetable calendar sync")
                            .foregroundStyle(LearnTheme.Colors.primaryText)
                        Text("Configure in Settings → Calendar sync")
                            .font(.caption)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }

                Button("Refresh home-screen widget") {
                    viewModel.refreshHomeScreenWidget()
                }
                .disabled(viewModel.isRequestingPermission)

                if let message = viewModel.widgetRefreshMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }

                Picker("Message badge (app open)", selection: inboxPollBinding) {
                    ForEach(LearnInboxPollInterval.allCases, id: \.rawValue) { option in
                        Text(option.label).tag(option)
                    }
                }

                Button("Refresh message badge now") {
                    viewModel.refreshMessageBadgeNow()
                }

                if let message = viewModel.inboxRefreshMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }

                Text("Assessment and notice alerts still require background scheduling (see docs/NOTIFICATIONS_WORKMANAGER_GAPS.md).")
                    .font(.caption2)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
            .listRowBackground(LearnGlassListRowBackground())
        }
        .learnInsetSettingsList()
        .learnShellNavigationDepth(1)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            LearnInlineNavBar(title: "Notifications")
        }
        .task { await viewModel.refreshAuthorizationStatus() }
    }

    private var assessmentBinding: Binding<Bool> {
        Binding(
            get: { viewModel.assessmentRemindersEnabled },
            set: { newValue in
                Task { await viewModel.setAssessmentRemindersEnabled(newValue) }
            }
        )
    }

    private var noticeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.noticeAlertsEnabled },
            set: { newValue in
                Task { await viewModel.setNoticeAlertsEnabled(newValue) }
            }
        )
    }

    private var inboxPollBinding: Binding<LearnInboxPollInterval> {
        Binding(
            get: { viewModel.inboxPollInterval },
            set: { viewModel.setInboxPollInterval($0) }
        )
    }

    @ViewBuilder
    private func notificationRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
        }
    }
}
