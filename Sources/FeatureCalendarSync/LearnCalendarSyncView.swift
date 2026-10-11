import CoreDesign
import SwiftUI

public struct LearnCalendarSyncView: View {
    @State private var viewModel: LearnCalendarSyncViewModel
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
            .listRowBackground(LearnTheme.Colors.card)

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
            .listRowBackground(LearnTheme.Colors.card)

            Section("Calendar sync") {
                Toggle("Timetable calendar sync", isOn: Binding(
                    get: { viewModel.preferences.isEnabled },
                    set: { viewModel.setEnabled($0) }
                ))
                Toggle("Sync automatically", isOn: Binding(
                    get: { viewModel.preferences.autoSyncEnabled },
                    set: { viewModel.setAutoSyncEnabled($0) }
                ))
                .disabled(!viewModel.preferences.isEnabled)
                Text("Automatic sync uses iOS Background App Refresh (about daily when enabled). Use Sync now for immediate updates.")
                    .font(.footnote)
                    .foregroundStyle(LearnTheme.Colors.secondaryText)
            }
            .listRowBackground(LearnTheme.Colors.card)

            Section("What to sync") {
                Toggle("Timetable lessons", isOn: Binding(
                    get: { viewModel.preferences.syncTimetable },
                    set: { viewModel.setSyncTimetable($0) }
                ))
                .disabled(!viewModel.preferences.isEnabled)
                Toggle("Assessment due dates", isOn: Binding(
                    get: { viewModel.preferences.syncAssessments },
                    set: { viewModel.setSyncAssessments($0) }
                ))
                .disabled(!viewModel.preferences.isEnabled)
            }
            .listRowBackground(LearnTheme.Colors.card)

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
                .listRowBackground(LearnTheme.Colors.card)
            }

            Section {
                Button {
                    Task { await viewModel.syncNow() }
                } label: {
                    HStack {
                        Text("Sync now")
                        Spacer()
                        if viewModel.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isSyncing || viewModel.authorizationStatus == .denied)

                if let status = viewModel.statusMessage ?? viewModel.preferences.lastSyncSummary {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
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
            }
            .listRowBackground(LearnTheme.Colors.card)
        }
        .scrollContentBackground(.hidden)
        .background(LearnTheme.Colors.background)
        .navigationTitle("Calendar sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
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
