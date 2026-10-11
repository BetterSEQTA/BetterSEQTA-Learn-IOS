import CoreDesign
import CoreSession
import FeatureNotifications
import UIKit
import FeatureAssessments
import FeatureCourses
import FeatureHome
import FeatureMessages
import FeatureNotices
import FeaturePortals
import FeatureCalendarSync
import FeatureNotifications
import FeatureSettings
import FeatureTimetable
import SwiftUI

struct MainShell: View {
    @ObservedObject var dependencies: LearnAppDependencies
    var versionName: String

    @StateObject private var shellViewModel: MainShellViewModel
    @StateObject private var homeViewModel: HomeViewModel
    @State private var timetableViewModel: LearnTimetableViewModel
    @State private var coursesViewModel: LearnCoursesViewModel
    @State private var assessmentsViewModel: LearnAssessmentsViewModel
    @State private var messagesViewModel: LearnMessagesViewModel
    @State private var portalsViewModel: LearnPortalsViewModel
    @State private var noticesViewModel: LearnNoticesViewModel
    @State private var settingsViewModel: LearnSettingsViewModel
    @State private var calendarSyncViewModel: LearnCalendarSyncViewModel

    @State private var selectedTab: ShellTab = .home
    @State private var tabNavigationForward = true
    @State private var showCalendarSync = false
    @State private var overlay: ShellOverlay?
    @State private var isDrawerOpen = false
    @State private var showLogoutConfirm = false
    @State private var showMessagesCompose = false
    @State private var showTimetableDatePicker = false
    @State private var shellNavigationDepth = 0
    @State private var inboxPollTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Binding var pendingShellRoute: LearnShellDeeplinkRoute?

    init(
        dependencies: LearnAppDependencies,
        pendingShellRoute: Binding<LearnShellDeeplinkRoute?> = .constant(nil),
        versionName: String = "0.1.0"
    ) {
        _pendingShellRoute = pendingShellRoute
        self.dependencies = dependencies
        self.versionName = versionName
        _shellViewModel = StateObject(
            wrappedValue: MainShellViewModel(studentRepository: dependencies.studentRepository)
        )
        _homeViewModel = StateObject(
            wrappedValue: HomeViewModel(
                studentRepository: dependencies.studentRepository,
                launchGate: dependencies.homeLaunchGate
            )
        )
        let repo = dependencies.studentRepository
        _timetableViewModel = State(initialValue: LearnTimetableViewModel(repository: repo))
        _coursesViewModel = State(initialValue: LearnCoursesViewModel(repository: repo))
        _assessmentsViewModel = State(initialValue: LearnAssessmentsViewModel(repository: repo))
        _messagesViewModel = State(initialValue: LearnMessagesViewModel(repository: repo))
        _portalsViewModel = State(initialValue: LearnPortalsViewModel(repository: repo))
        _noticesViewModel = State(initialValue: LearnNoticesViewModel(repository: repo))
        _settingsViewModel = State(initialValue: LearnSettingsViewModel(authRepository: dependencies.authRepository))
        _calendarSyncViewModel = State(
            initialValue: LearnCalendarSyncViewModel(repository: dependencies.calendarSyncRepository)
        )
    }

    private var onOverlay: Bool {
        overlay != nil
    }

    var body: some View {
        drawerShell
        .onAppear {
            shellViewModel.refreshUnreadMessages()
            restartInboxPollingIfNeeded()
            let calendarRepo = dependencies.calendarSyncRepository
            LearnCalendarSyncBackground.configure { @MainActor in
                _ = await calendarRepo.syncNow()
            }
            LearnCalendarSyncBackground.registerIfNeeded()
            let calendarPrefs = calendarRepo.loadPreferences()
            LearnCalendarSyncBackground.scheduleAutoSync(
                enabled: calendarPrefs.isEnabled && calendarPrefs.autoSyncEnabled
            )
            LearnHomeBackgroundRefresh.configure { @MainActor in
                homeViewModel.refresh(includeWarmup: false)
                shellViewModel.refreshUnreadMessages()
            }
            LearnHomeBackgroundRefresh.registerIfNeeded()
            LearnHomeBackgroundRefresh.schedulePeriodicSync(enabled: true)
        }
        .onChange(of: pendingShellRoute) { _, route in
            guard let route else { return }
            applyShellRoute(route)
            pendingShellRoute = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            shellViewModel.onAppResumed()
        }
        .onReceive(NotificationCenter.default.publisher(for: LearnInboxRefreshNotifier.pollIntervalDidChange)) { _ in
            restartInboxPollingIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                restartInboxPollingIfNeeded()
            } else {
                inboxPollTask?.cancel()
                inboxPollTask = nil
            }
        }
        .environment(\.learnMotionProfile, LearnMotionProfile.current(reduceMotion: reduceMotion))
        .confirmationDialog(
            "Log out?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) {
                Task { await dependencies.logout() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCalendarSync) {
            NavigationStack {
                LearnCalendarSyncView(viewModel: calendarSyncViewModel)
            }
        }
        .sheet(isPresented: $showTimetableDatePicker) {
            LearnGraphicalDateSheet(
                date: timetableViewModel.selectedDate,
                onConfirm: { date in
                    timetableViewModel.selectDate(date)
                    showTimetableDatePicker = false
                },
                onCancel: { showTimetableDatePicker = false }
            )
        }
    }

    private var drawerWidth: CGFloat {
        min(320, UIScreen.main.bounds.width * 0.88)
    }

    private var drawerShell: some View {
        ZStack(alignment: .leading) {
            mainScaffold
                .disabled(isDrawerOpen)
                .overlay {
                    if isDrawerOpen {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { closeDrawer() }
                    }
                }

            if isDrawerOpen {
                LearnShellDrawer(
                    displayName: homeViewModel.uiState.displayName,
                    versionName: versionName,
                    selectedTab: selectedTab,
                    selectedOverlay: overlay,
                    unreadMessages: shellViewModel.unreadMessageCount,
                    onSelectTab: { navigateToTab($0) },
                    onSelectOverlay: { navigateToOverlay($0) },
                    onLogout: { showLogoutConfirm = true }
                )
                .frame(width: drawerWidth)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(LearnTheme.Colors.separator)
                        .frame(width: 1 / UIScreen.main.scale)
                }
                .transition(.move(edge: .leading))
                .zIndex(2)
                .accessibilityAddTraits(.isModal)
            }
        }
        .animation(LearnMotion.drawerSpring, value: isDrawerOpen)
    }

    private func restartInboxPollingIfNeeded() {
        inboxPollTask?.cancel()
        let seconds = LearnInboxPollPreferencesStore().interval.seconds
        guard seconds > 0 else { return }
        inboxPollTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { return }
                shellViewModel.refreshUnreadMessages()
            }
        }
    }

    private var mainScaffold: some View {
        VStack(spacing: 0) {
            if shellNavigationDepth == 0 {
                topBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if !onOverlay {
                bottomBar
            }
        }
        .background { LearnScreenBackground() }
        .animation(LearnMotion.spatialStandardDefault, value: shellNavigationDepth)
        .onPreferenceChange(LearnShellChromeDepthKey.self) { shellNavigationDepth = $0 }
    }

    @ViewBuilder
    private var topBar: some View {
        Group {
            if onOverlay {
                LearnShellTopBar(
                    leading: .back {
                        withAnimation(LearnMotion.spatialStandardDefault) {
                            overlay = nil
                        }
                    },
                    title: overlay?.title ?? ""
                )
            } else if selectedTab == .messages {
                LearnShellTopBar(
                    leading: .menu {
                        LearnHaptics.lightImpact()
                        isDrawerOpen = true
                    },
                    title: ShellTab.messages.title,
                    trailing: {
                        Button {
                            LearnHaptics.lightImpact()
                            showMessagesCompose = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.body.weight(.semibold))
                                .frame(width: 32, height: 32)
                        }
                        .learnPressFeedback(scale: 0.92)
                        .accessibilityLabel("Compose message")
                    }
                )
            } else if selectedTab == .home {
                LearnShellTopBar(
                    leading: .menu {
                        LearnHaptics.lightImpact()
                        isDrawerOpen = true
                    },
                    center: {
                        LearnShellHeaderDate(date: homeViewModel.uiState.selectedDate)
                    },
                    trailing: {
                        settingsToolbarButton
                    }
                )
            } else if selectedTab == .timetable {
                LearnShellTopBar(
                    leading: .menu {
                        LearnHaptics.lightImpact()
                        isDrawerOpen = true
                    },
                    center: {
                        LearnShellHeaderDate(date: timetableViewModel.selectedDate)
                    },
                    trailing: {
                        HStack(spacing: 2) {
                            if !timetableViewModel.isSelectedDateToday {
                                Button("Today") {
                                    LearnHaptics.selection()
                                    timetableViewModel.goToToday()
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LearnTheme.Colors.accent)
                                .learnPressFeedback(scale: 0.96)
                            }
                            Button {
                                LearnHaptics.lightImpact()
                                showTimetableDatePicker = true
                            } label: {
                                Image(systemName: "calendar")
                                    .font(.body.weight(.medium))
                                    .frame(width: 32, height: 32)
                            }
                            .learnPressFeedback(scale: 0.92)
                            .accessibilityLabel("Pick date")
                            settingsToolbarButton
                        }
                    }
                )
            } else {
                LearnShellTopBar(
                    leading: .menu {
                        LearnHaptics.lightImpact()
                        isDrawerOpen = true
                    },
                    title: selectedTab.title,
                    trailing: {
                        settingsToolbarButton
                    }
                )
            }
        }
        .foregroundStyle(LearnTheme.Colors.primaryText)
    }

    @ViewBuilder
    private var tabContent: some View {
        if let overlay {
            overlayView(overlay)
                .transition(LearnMotion.overlaySlide(richAnimations: !reduceMotion))
        } else {
            Group {
                switch selectedTab {
                case .home:
                    HomeScreen(
                        viewModel: homeViewModel,
                        navigation: homeNavigation
                    )
                case .timetable:
                    LearnTimetableView(viewModel: timetableViewModel)
                case .courses:
                    LearnCoursesView(viewModel: coursesViewModel)
                case .tasks:
                    LearnAssessmentsView(viewModel: assessmentsViewModel)
                case .messages:
                    LearnMessagesView(
                        viewModel: messagesViewModel,
                        showCompose: $showMessagesCompose
                    )
                }
            }
            .id(selectedTab)
            .transition(
                LearnMotion.tabSlide(
                    forward: tabNavigationForward,
                    richAnimations: !reduceMotion
                )
            )
            .animation(LearnMotion.spatialStandardDefault, value: selectedTab)
        }
    }

    @ViewBuilder
    private func overlayView(_ route: ShellOverlay) -> some View {
        switch route {
        case .portals:
            LearnPortalsView(viewModel: portalsViewModel)
        case .notices:
            LearnNoticesView(viewModel: noticesViewModel)
        case .settings:
            NavigationStack {
                LearnSettingsView(
                    viewModel: settingsViewModel,
                    onLogout: { showLogoutConfirm = true },
                    onCalendarSyncTap: { showCalendarSync = true }
                )
            }
        }
    }

    private var bottomBar: some View {
        LearnShellBottomBar(
            selectedTab: Binding(
                get: { ShellTab.allCases.firstIndex(of: selectedTab) ?? 0 },
                set: { index in
                    let tab = ShellTab.allCases[index]
                    selectTab(tab)
                }
            ),
            tabs: ShellTab.allCases.map { tab in
                (
                    title: tab.title,
                    systemImage: tab.systemImage,
                    badge: tab == .messages ? shellViewModel.unreadMessageCount : nil
                )
            },
            onSelect: { index in
                selectTab(ShellTab.allCases[index])
            }
        )
    }

    private func selectTab(_ tab: ShellTab) {
        let tabs = ShellTab.allCases
        let newIndex = tabs.firstIndex(of: tab) ?? 0
        let oldIndex = tabs.firstIndex(of: selectedTab) ?? 0
        tabNavigationForward = newIndex >= oldIndex
        withAnimation(LearnMotion.spatialStandardDefault) {
            selectedTab = tab
            overlay = nil
        }
        closeDrawer()
    }

    private var homeNavigation: HomeNavigationCallbacks {
        HomeNavigationCallbacks(
            onPortalsClick: { Task { @MainActor in navigateToOverlay(.portals) } },
            onNoticesClick: { Task { @MainActor in navigateToOverlay(.notices) } },
            onCoursesClick: { Task { @MainActor in navigateToTab(.courses) } },
            onMessagesClick: { Task { @MainActor in navigateToTab(.messages) } },
            onTimetableClick: { Task { @MainActor in navigateToTab(.timetable) } },
            onAssessmentsClick: { Task { @MainActor in navigateToTab(.tasks) } },
            onAssessmentClick: { assessment in
                Task { @MainActor in
                    assessmentsViewModel.openAssessment(assessment)
                    navigateToTab(.tasks)
                }
            }
        )
    }

    private var settingsToolbarButton: some View {
        Button(action: { navigateToOverlay(.settings) }) {
            Image(systemName: "gearshape")
                .font(.body.weight(.medium))
                .frame(width: 32, height: 32)
        }
        .learnPressFeedback(scale: 0.92)
        .accessibilityLabel("Settings")
    }

    private func closeDrawer() {
        isDrawerOpen = false
    }

    private func navigateToTab(_ tab: ShellTab) {
        selectTab(tab)
    }

    private func navigateToOverlay(_ route: ShellOverlay) {
        withAnimation(LearnMotion.spatialStandardDefault) {
            overlay = route
        }
        closeDrawer()
    }

    private func applyShellRoute(_ route: LearnShellDeeplinkRoute) {
        switch route {
        case .tab(let tab):
            navigateToTab(tab)
        case .overlay(let overlayRoute):
            navigateToOverlay(overlayRoute)
        }
    }
}
