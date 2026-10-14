import CoreDesign
import SwiftUI

public struct LearnCalendarSyncView: View {
    @State private var viewModel: LearnCalendarSyncViewModel
    @State private var inlineToast: String?
    @Environment(\.dismiss) private var dismiss
    public init(viewModel: LearnCalendarSyncViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            Section {
                Text("Export upcoming lessons and assessment due dates to an iOS calendar. Sync runs on demand from this screen.")
                    .font(.subheadline)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
            .listRowBackground(LearnGlassListRowBackground())

            Section("Access") {
                Label(accessLabel, systemImage: accessIcon)
                if viewModel.authorizationStatus == .notDetermined {
                    Button("Allow calendar access") {
                        Task { await viewModel.requestAccess() }
                    }
                } else if viewModel.authorizationStatus == .denied {
                    Text("Open iOS Settings → Privacy → Calendars to allow access.")
                        .font(.footnote)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
            .listRowBackground(LearnGlassListRowBackground())

            Section("Calendar sync") {
                LearnSwitchDisclosure(
                    "Timetable calendar sync",
                    isOn: Binding(
                        get: { viewModel.preferences.isEnabled },
                        set: { viewModel.setEnabled($0) }
                    )
                ) {
                    Toggle("Sync automatically", isOn: Binding(
                        get: { viewModel.preferences.autoSyncEnabled },
                        set: { viewModel.setAutoSyncEnabled($0) }
                    ))
                    Text("Automatic sync uses iOS Background App Refresh (about daily when enabled). Use Sync now for immediate updates.")
                        .font(.footnote)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    Toggle("Timetable lessons", isOn: Binding(
                        get: { viewModel.preferences.syncTimetable },
                        set: { viewModel.setSyncTimetable($0) }
                    ))
                    Toggle("Assessment due dates", isOn: Binding(
                        get: { viewModel.preferences.syncAssessments },
                        set: { viewModel.setSyncAssessments($0) }
                    ))
                }
            }
            .listRowBackground(LearnGlassListRowBackground())

            if viewModel.authorizationStatus == .authorized, !viewModel.calendars.isEmpty {
                Section("Destination calendar") {
                    Picker(
                        "Calendar",
                        selection: Binding(
                            get: { viewModel.preferences.selectedCalendarIdentifier ?? "" },
                            set: { viewModel.selectCalendar(id: $0.isEmpty ? nil : $0) }
                        )
                    ) {
                        ForEach(viewModel.calendars) { calendar in
                            Text(calendar.title).tag(calendar.id)
                        }
                    }
                }
                .listRowBackground(LearnGlassListRowBackground())
            }

            Section {
                LearnStatefulCapsuleButton(
                    title: "Sync now",
                    successTitle: "Synced",
                    isEnabled: viewModel.authorizationStatus != .denied && !viewModel.isSyncing
                ) {
                    await viewModel.syncNow()
                    let ok = viewModel.errorMessage == nil
                    if ok, let message = viewModel.statusMessage ?? viewModel.preferences.lastSyncSummary {
                        inlineToast = message
                    }
                    return ok
                }

                if let status = viewModel.statusMessage ?? viewModel.preferences.lastSyncSummary {
                    HStack(alignment: .top, spacing: 8) {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LearnCopyMorphIconButton(text: status, accessibilityLabel: "Copy sync status")
                    }
                }
                if let last = viewModel.preferences.lastSyncedAt {
                    Text("Last sync: \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Remove BetterSEQTA Learn events from the iOS Calendar app. This does not change SEQTA data.")
                        .font(.footnote)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    HStack {
                        Spacer(minLength: 0)
                        LearnInlineDeleteConfirm(label: "Remove synced calendar events") {
                            Task {
                                await viewModel.removeSyncedCalendarItems()
                                if let message = viewModel.statusMessage {
                                    inlineToast = message
                                }
                            }
                        }
                        .disabled(viewModel.isRemovingSyncedEvents || viewModel.authorizationStatus != .authorized)
                    }
                }
            }
            .listRowBackground(LearnGlassListRowBackground())
        }
        .learnInsetSettingsList()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    LearnHaptics.lightImpact()
                    dismiss()
                }
            }
        }
        .presentationDragIndicator(.visible)
        .learnLiquidGlassSheetBackground()
        .learnInlineToast(message: $inlineToast)
        .onAppear { viewModel.refresh() }
    }

    private var accessLabel: String {
        switch viewModel.authorizationStatus {
        case .notDetermined: "Not requested yet"
        case .authorized: "Allowed"
        case .denied: "Denied"
        case .restricted: "Restricted"
        }
    }

    private var accessIcon: String {
        switch viewModel.authorizationStatus {
        case .authorized: "checkmark.circle.fill"
        case .denied, .restricted: "xmark.circle.fill"
        case .notDetermined: "questionmark.circle"
        }
    }
}
