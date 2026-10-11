import SwiftUI
import UIKit
import WebKit

/// Renders SEQTA HTML (notices, messages) on the app background with readable typography.
public struct LearnHTMLContentView: UIViewRepresentable {
    public let html: String
    public var minHeight: CGFloat = 200
    public var allowsInternalScrolling: Bool = false

    public init(html: String, minHeight: CGFloat = 200, allowsInternalScrolling: Bool = false) {
        self.html = html
        self.minHeight = minHeight
        self.allowsInternalScrolling = allowsInternalScrolling
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = allowsInternalScrolling
        webView.navigationDelegate = context.coordinator
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        let wrapped = Self.document(html: html)
        if context.coordinator.lastLoaded != wrapped {
            context.coordinator.lastLoaded = wrapped
            webView.loadHTMLString(wrapped, baseURL: nil)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public static func document(html: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
        :root { color-scheme: dark; }
        body {
          font: -apple-system-body;
          line-height: 1.45;
          color: #f2f2f7;
          background: transparent;
          margin: 0;
          padding: 0;
          word-wrap: break-word;
        }
        p { margin: 0 0 0.75em 0; }
        ul, ol { margin: 0 0 0.75em 1.1em; padding: 0; }
        h1, h2, h3 { font-weight: 600; margin: 0 0 0.5em 0; font-size: 1.1em; }
        a { color: #8ea8ff; }
        img { max-width: 100%; height: auto; border-radius: 6px; }
        table { border-collapse: collapse; max-width: 100%; }
        td, th { border: 1px solid rgba(255,255,255,0.12); padding: 6px 8px; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
    }

    public final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: LearnHTMLContentView
        var lastLoaded: String?

        init(parent: LearnHTMLContentView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !parent.allowsInternalScrolling else { return }
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] height, _ in
                guard let self, let height = height as? CGFloat, height > 0 else { return }
                let resolved = max(self.parent.minHeight, height + 8)
                webView.constraints.forEach { webView.removeConstraint($0) }
                webView.heightAnchor.constraint(equalToConstant: resolved).isActive = true
            }
        }

        @MainActor
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                await UIApplication.shared.open(url)
                return .cancel
            }
            return .allow
        }
    }
}
