import CoreDesign
import SwiftUI
import WebKit

public struct LoginWebView: View {
    @Environment(\.dismiss) private var dismiss

    private let baseUrl: String
    private let onCaptured: (String, String) -> Void

    @State private var finished = false

    public init(baseUrl: String, onCaptured: @escaping (String, String) -> Void) {
        self.baseUrl = baseUrl
        self.onCaptured = onCaptured
    }

    public var body: some View {
        NavigationStack {
            LoginWebViewRepresentable(
                baseUrl: baseUrl,
                finished: $finished,
                onCaptured: { url, jsession in
                    onCaptured(url, jsession)
                    dismiss()
                }
            )
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("School SEQTA login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct LoginWebViewRepresentable: UIViewRepresentable {
    let baseUrl: String
    @Binding var finished: Bool
    let onCaptured: (String, String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(baseUrl: baseUrl, finished: $finished, onCaptured: onCaptured)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        let learnURL = WebSessionCookieParser.learnUrl(baseUrl: baseUrl)
        if let url = URL(string: learnURL) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let baseUrl: String
        @Binding var finished: Bool
        let onCaptured: (String, String) -> Void

        init(baseUrl: String, finished: Binding<Bool>, onCaptured: @escaping (String, String) -> Void) {
            self.baseUrl = baseUrl
            self._finished = finished
            self.onCaptured = onCaptured
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !finished else { return }
            let normalized = WebSessionCookieParser.normalizeSchoolBaseUrl(baseUrl)
            guard let host = URL(string: normalized)?.host else { return }
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                let relevant = cookies.filter { $0.domain.contains(host) || host.contains($0.domain) }
                let header = relevant.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                let jsessionId = WebSessionCookieParser.parseJsessionId(cookieHeader: header)
                let pageURL = webView.url?.absoluteString ?? ""
                if let jsessionId, pageURL.contains("/seqta/") {
                    DispatchQueue.main.async {
                        self.finished = true
                        self.onCaptured(normalized, jsessionId)
                    }
                }
            }
        }
    }
}
