import CoreSession
import FeatureNotifications
import SwiftUI

@main
public struct BetterSEQTALearnApp: App {
    @StateObject private var sessionStore = LearnSessionStore()

    public init() {
        LearnNotificationsCoordinator.registerCategories()
    }

    public var body: some Scene {
        WindowGroup {
            ContentView(sessionStore: sessionStore)
                .environmentObject(sessionStore)
                .task {
                    _ = await LearnNotificationsCoordinator.requestAuthorizationIfNeeded()
                }
        }
    }
}
