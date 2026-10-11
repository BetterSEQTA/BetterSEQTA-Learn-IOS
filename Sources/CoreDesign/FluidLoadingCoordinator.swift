import Combine
import SwiftUI

@MainActor
public final class FluidLoadingCoordinator: ObservableObject {
    @Published public private(set) var isActive = false
    @Published public private(set) var progress: Double = 0
    @Published public private(set) var phaseText: String = ""

    public init() {}

    public func begin(phaseText: String, progress: Double = 0.15) {
        isActive = true
        self.phaseText = phaseText
        self.progress = min(max(progress, 0), 1)
    }

    public func update(progress: Double, phaseText: String? = nil) {
        self.progress = min(max(progress, 0), 1)
        if let phaseText { self.phaseText = phaseText }
    }

    public func end() {
        progress = 1
        phaseText = ""
        isActive = false
    }
}
