import CoreDesign
import SwiftUI

enum HomeColourUtils {
    static func parseSubjectColour(_ raw: String?) -> Color {
        LearnSubjectColour.parse(raw)
    }
}
