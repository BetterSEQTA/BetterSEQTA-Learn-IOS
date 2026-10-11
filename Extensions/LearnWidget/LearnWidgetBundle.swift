import WidgetKit
import SwiftUI

@main
public struct LearnWidgetBundle: WidgetBundle {
    public init() {}

    public var body: some Widget {
        LearnTimelineWidget()
    }
}
