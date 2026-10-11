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
    @State private var launchOverlayDismissed = false
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

    private var homeReady: Bool {
        dependencies.homeLaunchGate.isHomeReady
    }

    private var onOverlay: Bool {
        overlay != nil
    }

    var body: some View {
        ZStack {
            if homeReady {
                drawerShell
            }

            if !launchOverlayDismissed {
                AppLaunchLoadingOverlay(
                    visible: !homeReady,
                    versionName: versionName,
                    onDismissed: { launchOverlayDismissed = true }
                )
                .zIndex(20)
            }
        }
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
    }

    private var drawerShell: some View {
        ZStack(alignment: .leading) {
            mainScaffold
                .disabled(isDrawerOpen)
                .overlay {
                    if isDrawerOpen {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                            .onTapGesture { closeDrawer() }
                    }
                }

            if isDrawerOpen {
                drawerContent
                    .frame(width: min(320, UIScreen.main.bounds.width * 0.86))
                    .background(LearnTheme.Colors.background)
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 4, y: 0)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
                    .accessibilityAddTraits(.isModal)
            }
        }
        .animation(LearnMotion.spatialStandardDefault, value: isDrawerOpen)
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
            topBar
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if !onOverlay {
                bottomBar
            }
        }
        .background(LearnTheme.Colors.background)
    }

    @ViewBuilder
    private var topBar: some View {
        HStack {
            if onOverlay {
                Button(action: { overlay = nil }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                Text(overlay?.title ?? "")
                    .font(.headline)
            } else {
                Button(action: { isDrawerOpen = true }) {
                    Image(systemName: "line.3.horizontal")
                }
                .accessibilityLabel("Open menu")
                Text(selectedTab.title)
                    .font(.headline)
                Spacer()
                Button(action: { navigateToOverlay(.settings) }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .foregroundStyle(LearnTheme.Colors.primaryText)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(LearnTheme.Colors.card.opacity(0.5))
    }

    @ViewBuilder
    private var tabContent: some View {
        if let overlay {
            overlayView(overlay)
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
                    LearnMessagesView(viewModel: messagesViewModel)
                }
            }
            .id(selectedTab)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .animation(LearnMotion.screenFadeIn, value: selectedTab)
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
        HStack {
            ForEach(ShellTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                    overlay = nil
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20))
                            if tab == .messages, shellViewModel.unreadMessageCount > 0 {
                                Text("\(min(shellViewModel.unreadMessageCount, 99))")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(4)
                                    .background(Color.red, in: Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                        Text(tab.title)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(
                        selectedTab == tab && overlay == nil
                            ? Color.accentColor
                            : LearnTheme.Colors.secondaryText
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(LearnTheme.Colors.card.opacity(0.6))
    }

    private var drawerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BetterSEQTA Learn")
                .font(.title2.weight(.bold))
                .foregroundStyle(LearnTheme.Colors.primaryText)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)

            drawerSectionLabel("Main")
            ForEach(ShellTab.allCases, id: \.self) { tab in
                drawerItem(
                    title: tab.title,
                    systemImage: tab.systemImage,
                    selected: selectedTab == tab && overlay == nil
                ) {
                    navigateToTab(tab)
                }
            }

            Divider().padding(.vertical, 12)

            drawerSectionLabel("More")
            drawerItem(title: "Welcome Portals", systemImage: "globe", selected: overlay == .portals) {
                navigateToOverlay(.portals)
            }
            drawerItem(title: "Notices", systemImage: "megaphone", selected: overlay == .notices) {
                navigateToOverlay(.notices)
            }
            drawerItem(title: "Settings", systemImage: "gearshape", selected: overlay == .settings) {
                navigateToOverlay(.settings)
            }

            Spacer()

            Divider()
            Button(role: .destructive) {
                closeDrawer()
                showLogoutConfirm = true
            } label: {
                Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func drawerSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(LearnTheme.Colors.secondaryText)
            .padding(.horizontal, 28)
            .padding(.vertical, 4)
    }

    private func drawerItem(
        title: String,
        systemImage: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 24)
                    .foregroundStyle(selected ? Color.accentColor : LearnTheme.Colors.primaryText)
                Text(title)
                    .fontWeight(selected ? .semibold : .regular)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(selected ? LearnTheme.Colors.card : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.35), lineWidth: 1)
                }
            }
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected ? Color.accentColor : LearnTheme.Colors.primaryText)
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

    private func closeDrawer() {
        isDrawerOpen = false
    }

    private func navigateToTab(_ tab: ShellTab) {
        selectedTab = tab
        overlay = nil
        closeDrawer()
    }

    private func navigateToOverlay(_ route: ShellOverlay) {
        overlay = route
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
