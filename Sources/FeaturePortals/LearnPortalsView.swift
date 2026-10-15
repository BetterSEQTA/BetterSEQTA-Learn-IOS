import CoreDesign
import CoreSession
import Domain
import SwiftUI

public struct LearnPortalsView: View {
    @EnvironmentObject private var sessionStore: LearnSessionStore
    @State private var viewModel: LearnPortalsViewModel
    @State private var selectedPortal: Portal?

    public init(viewModel: LearnPortalsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 12)]

    public var body: some View {
        Group {
            if viewModel.isLoading {
                LearnLoadingState(preset: .portalGrid(cells: 8))
            } else if let error = viewModel.errorMessage {
                LearnErrorBanner(message: error) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.portals.isEmpty {
                LearnEmptyState(
                    title: "No portals available",
                    message: "There are currently no portals configured for your account."
                )
            } else {
                ScrollView {
                    Text("Tap a portal to open its content")
                        .font(.subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.portals.enumerated()), id: \.element.id) { index, portal in
                            Button {
                                LearnHaptics.lightImpact()
                                selectedPortal = portal
                            } label: {
                                LearnPortalCard(portal: portal)
                            }
                            .learnRowPress(scale: 0.97)
                            .learnListEntrance(index: index)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background { LearnScreenBackground() }
        .learnShellNavigationDepth(0)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $selectedPortal) { portal in
            LearnPortalDetailSheet(portal: portal, session: sessionStore.session)
        }
    }
}

private struct LearnPortalCard: View {
    let portal: Portal

    var body: some View {
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: portal.isPowerPortal ? "bolt.fill" : "square.grid.2x2")
                    .foregroundStyle(Color.accentColor)
                Text(portal.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        }
    }
}

private struct LearnPortalDetailSheet: View {
    let portal: Portal
    let session: SessionData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let urlString = portal.url,
                   let url = URL(string: urlString),
                   session.isAuthenticated {
                    LearnPortalWebView(pageURL: url, jsessionId: session.jsessionId)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(portal.title)
                            .font(.title2.weight(.semibold))
                        Text("This portal is not available in the app yet.")
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                        Spacer()
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { LearnScreenBackground() }
            .navigationTitle(portal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension Portal: Identifiable {}
