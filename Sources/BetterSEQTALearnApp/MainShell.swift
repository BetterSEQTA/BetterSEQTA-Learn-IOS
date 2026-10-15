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
    @State private var showCalendarSync = false
    @State private var overlay: ShellOverlay?
    @State private var isDrawerOpen = false
    @State private var showLogoutConfirm = false
    @State private var showMessagesCompose = false
    @State private var showTimetableDatePicker = false
    @State private var isSettingsPresented = false
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
                    onOpenSettings: { openSettings() },
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

    private var showsShellTopBar: Bool {
        shellNavigationDepth == 0 && !isSettingsPresented
    }

    private var mainScaffold: some View {
        VStack(spacing: 0) {
            if showsShellTopBar {
                topBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Group {
                if let overlayRoute = overlay {
                    overlayView(overlayRoute)
                        .transition(LearnMotion.overlaySlide(richAnimations: !reduceMotion))
                } else {
                    shellTabView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background { LearnScreenBackground() }
        .animation(LearnMotion.spatialStandardDefault, value: shellNavigationDepth)
        .animation(LearnMotion.spatialStandardDefault, value: overlay)
        .animation(LearnMotion.spatialStandardDefault, value: isSettingsPresented)
        .onPreferenceChange(LearnShellChromeDepthKey.self) { shellNavigationDepth = $0 }
    }

    /// System floating tab bar with one root stack per tab (reliable hit testing and chrome).
    private var shellTabView: some View {
        TabView(selection: $selectedTab) {
            ForEach(ShellTab.allCases, id: \.self) { tab in
                shellTabRoot(tab)
                    .tabItem { Label(tab.title, systemImage: tab.systemImage) }
                    .badge(tab == .messages && messagesTabBadge > 0 ? messagesTabBadge : 0)
                    .tag(tab)
            }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: selectedTab) { previous, newTab in
            guard previous != newTab else { return }
            LearnHaptics.selection()
            overlay = nil
            isSettingsPresented = false
        }
    }

    @ViewBuilder
    private func shellTabRoot(_ tab: ShellTab) -> some View {
        Group {
            switch tab {
            case .home:
                shellTabContainer(tab: .home) {
                    HomeScreen(viewModel: homeViewModel, navigation: homeNavigation)
                }
            case .timetable:
                shellTabContainer(tab: .timetable) {
                    LearnTimetableView(viewModel: timetableViewModel)
                }
            case .courses:
                shellTabContainer(tab: .courses) {
                    LearnCoursesView(viewModel: coursesViewModel)
                }
            case .assessments:
                shellTabContainer(tab: .assessments) {
                    LearnAssessmentsView(viewModel: assessmentsViewModel)
                }
            case .messages:
                shellTabContainer(tab: .messages) {
                    LearnMessagesView(viewModel: messagesViewModel, showCompose: $showMessagesCompose)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func shellTabContainer<Content: View>(
        tab: ShellTab,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        NavigationStack {
            content()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: settingsPresentationBinding(for: tab)) {
                    settingsPage
                }
        }
    }

    private var settingsPage: some View {
        LearnSettingsView(
            viewModel: settingsViewModel,
            onLogout: { showLogoutConfirm = true },
            onCalendarSyncTap: { showCalendarSync = true }
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func settingsPresentationBinding(for tab: ShellTab) -> Binding<Bool> {
        Binding(
            get: { selectedTab == tab && isSettingsPresented },
            set: { isSettingsPresented = $0 }
        )
    }

    @ViewBuilder
    private var topBar: some View {
        Group {
            if let overlayRoute = overlay {
                LearnShellTopBar(
                    leading: .back {
                        withAnimation(LearnMotion.spatialStandardDefault) {
                            self.overlay = nil
                        }
                    },
                    title: overlayRoute.title
                )
            } else if selectedTab == .messages {
                LearnShellTopBar(
                    leading: .menu { openDrawer() },
                    title: ShellTab.messages.title,
                    trailing: {
                        Button {
                            LearnHaptics.lightImpact()
                            showMessagesCompose = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.body.weight(.semibold))
                                .frame(width: 40, height: 40)
                        }
                        .learnShellTopBarAction("compose")
                        .accessibilityLabel("Compose message")
                    }
                )
            } else if selectedTab == .home {
                LearnShellTopBar(
                    leading: .menu { openDrawer() },
                    morphAnimationValue: homeViewModel.uiState.selectedDate,
                    center: {
                        LearnShellHeaderDate(
                            date: homeViewModel.uiState.selectedDate,
                            style: .toolbar,
                            alignment: .center
                        )
                    },
                    trailing: { settingsToolbarButton }
                )
            } else if selectedTab == .timetable {
                LearnShellTopBar(
                    leading: .menu { openDrawer() },
                    morphAnimationValue: timetableViewModel.isSelectedDateToday,
                    center: {
                        LearnShellHeaderDate(
                            date: timetableViewModel.selectedDate,
                            style: .toolbar,
                            alignment: .center
                        )
                    },
                    trailing: { timetableTopBarTrailing }
                )
            } else {
                LearnShellTopBar(
                    leading: .menu { openDrawer() },
                    title: selectedTab.title,
                    trailing: { settingsToolbarButton }
                )
            }
        }
        .foregroundStyle(LearnTheme.Colors.primaryText)
    }

    @ViewBuilder
    private var timetableTopBarTrailing: some View {
        if !timetableViewModel.isSelectedDateToday {
            Button("Today") {
                LearnHaptics.selection()
                timetableViewModel.goToToday()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(LearnTheme.Colors.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .learnShellTopBarAction("today", shape: .capsule)
        }
        Button {
            LearnHaptics.lightImpact()
            showTimetableDatePicker = true
        } label: {
            Image(systemName: "calendar")
                .font(.body.weight(.medium))
                .frame(width: 40, height: 40)
        }
        .learnShellTopBarAction("calendar")
        .accessibilityLabel("Pick date")
        settingsToolbarButton
    }

    private var messagesTabBadge: Int {
        let count = shellViewModel.unreadMessageCount
        return count > 0 ? count : 0
    }

    @ViewBuilder
    private func overlayView(_ route: ShellOverlay) -> some View {
        switch route {
        case .portals:
            LearnPortalsView(viewModel: portalsViewModel)
        case .notices:
            LearnNoticesView(viewModel: noticesViewModel)
        }
    }

    private func selectTab(_ tab: ShellTab) {
        guard tab != selectedTab else { return }
        LearnHaptics.selection()
        withAnimation(LearnMotion.spatialStandardDefault) {
            selectedTab = tab
            overlay = nil
            isSettingsPresented = false
        }
    }

    private var homeNavigation: HomeNavigationCallbacks {
        HomeNavigationCallbacks(
            onPortalsClick: { Task { @MainActor in navigateToOverlay(.portals) } },
            onNoticesClick: { Task { @MainActor in navigateToOverlay(.notices) } },
            onCoursesClick: { Task { @MainActor in navigateToTab(.courses) } },
            onMessagesClick: { Task { @MainActor in navigateToTab(.messages) } },
            onTimetableClick: { Task { @MainActor in navigateToTab(.timetable) } },
            onAssessmentsClick: { Task { @MainActor in navigateToTab(.assessments) } },
            onAssessmentClick: { assessment in
                Task { @MainActor in
                    assessmentsViewModel.openAssessment(assessment)
                    navigateToTab(.assessments)
                }
            }
        )
    }

    private var settingsToolbarButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape")
                .font(.body.weight(.medium))
                .frame(width: 40, height: 40)
        }
        .learnShellTopBarAction("settings")
        .accessibilityLabel("Settings")
    }

    private func openDrawer() {
        LearnHaptics.lightImpact()
        isDrawerOpen = true
    }

    private func openSettings() {
        LearnHaptics.lightImpact()
        withAnimation(LearnMotion.spatialStandardDefault) {
            overlay = nil
            isSettingsPresented = true
        }
        closeDrawer()
    }

    private func closeDrawer() {
        isDrawerOpen = false
    }

    private func navigateToTab(_ tab: ShellTab) {
        selectTab(tab)
        closeDrawer()
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
        case .settings:
            openSettings()
        }
    }
}
