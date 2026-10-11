import CoreDesign
import SwiftUI

struct LearnMessageHTMLWebView: View {
    let html: String

    var body: some View {
        LearnHTMLContentView(html: html, minHeight: 200)
    }
}
