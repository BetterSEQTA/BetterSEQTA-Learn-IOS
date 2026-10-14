import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnPortalsViewModel {
    public var portals: [Portal] = []
    public var isLoading = false
    public var errorMessage: String?

    private let repository: StudentRepository
    nonisolated(unsafe) private var cacheListenerTask: Task<Void, Never>?

    public init(repository: StudentRepository) {
        self.repository = repository
        cacheListenerTask = StudentCacheUpdateListener.start(prefixes: ["portals"]) { [weak self] in
            await self?.hydrateFromCache()
        }
    }

    deinit {
        cacheListenerTask?.cancel()
    }

    private func hydrateFromCache() async {
        if let cached: [Portal] = await repository.cachedValue(StudentCacheKey.portals.storageKey) {
            portals = cached
        }
    }

    public func load() async {
        guard !isLoading else { return }
        await hydrateFromCache()
        isLoading = portals.isEmpty
        errorMessage = nil
        defer { isLoading = false }

        switch await repository.getPortals() {
        case .success(let value):
            portals = value
        case .failure(let error):
            errorMessage = error.localizedDescription
            portals = []
        }
    }
}
