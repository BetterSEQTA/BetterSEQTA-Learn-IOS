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

    public init(repository: StudentRepository) {
        self.repository = repository
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
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
