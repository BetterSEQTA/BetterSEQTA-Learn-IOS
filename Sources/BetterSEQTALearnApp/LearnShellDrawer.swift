import CoreDesign
import SwiftUI

/// Standard sidebar list (system `.sidebar` style, flat elevated background).
struct LearnShellDrawer: View {
    let displayName: String?
    let versionName: String
    let selectedTab: ShellTab
    let selectedOverlay: ShellOverlay?
    let unreadMessages: Int
    let onSelectTab: (ShellTab) -> Void
    let onSelectOverlay: (ShellOverlay) -> Void
    let onOpenSettings: () -> Void
    let onLogout: () -> Void

    var body: some View {
        List {
            Section {
                Text(profileTitle)
                    .font(.title2.weight(.bold))
                Text("BetterSEQTA Learn")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(ShellTab.allCases, id: \.self) { tab in
                    sidebarRow(
                        title: tab.title,
                        systemImage: tab.systemImage,
                        badge: tab == .messages ? unreadMessages : nil,
                        selected: selectedTab == tab && selectedOverlay == nil
                    ) {
                        LearnHaptics.selection()
                        onSelectTab(tab)
                    }
                }
            }

            Section {
                sidebarRow(
                    title: "Portals",
                    systemImage: "globe",
                    badge: nil,
                    selected: selectedOverlay == .portals
                ) {
                    LearnHaptics.selection()
                    onSelectOverlay(.portals)
                }
                sidebarRow(
                    title: "Notices",
                    systemImage: "megaphone",
                    badge: nil,
                    selected: selectedOverlay == .notices
                ) {
                    LearnHaptics.selection()
                    onSelectOverlay(.notices)
                }
                sidebarRow(
                    title: "Settings",
                    systemImage: "gearshape",
                    badge: nil,
                    selected: false
                ) {
                    LearnHaptics.selection()
                    onOpenSettings()
                }
            }

            Section {
                Button(role: .destructive) {
                    LearnHaptics.lightImpact()
                    onLogout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } footer: {
                Text("Version \(versionName)")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .learnSidebarGlass()
    }

    private var profileTitle: String {
        if let displayName, !displayName.isEmpty { return displayName }
        return "Student"
    }

    private func sidebarRow(
        title: String,
        systemImage: String,
        badge: Int?,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                    .labelStyle(.titleAndIcon)
                Spacer(minLength: 0)
                if let badge, badge > 0 {
                    Text("\(min(badge, 99))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 12))
        .listRowBackground(
            selected ? LearnTheme.Colors.accent.opacity(0.14) : nil
        )
    }
}
