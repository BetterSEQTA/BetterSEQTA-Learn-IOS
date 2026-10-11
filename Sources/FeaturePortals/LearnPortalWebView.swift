import SwiftUI
import WebKit

struct LearnPortalWebView: UIViewRepresentable {
    let pageURL: URL
    let jsessionId: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        injectSessionCookie(into: webView) { webView.load(URLRequest(url: pageURL)) }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func injectSessionCookie(into webView: WKWebView, completion: @escaping () -> Void) {
        guard let host = pageURL.host else {
            completion()
            return
        }
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .domain: host,
            .path: "/",
            .name: "JSESSIONID",
            .value: jsessionId,
            .secure: "TRUE",
        ]
        guard let cookie = HTTPCookie(properties: cookieProperties) else {
            completion()
            return
        }
        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
            completion()
        }
    }
}
