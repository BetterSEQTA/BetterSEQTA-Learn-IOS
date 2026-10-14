import SwiftUI
import UIKit
import WebKit

public enum LearnHTMLContentVariant: Sendable {
    /// Notices, messages — light text on app chrome.
    case standard
    /// Course pages — neutralise SEQTA inline black-on-white editor styles on dark cards.
    case course
}

/// Renders SEQTA HTML (notices, messages) on the app background with readable typography.
public struct LearnHTMLContentView: UIViewRepresentable {
    public let html: String
    public var minHeight: CGFloat = 200
    public var allowsInternalScrolling: Bool = false
    public var variant: LearnHTMLContentVariant = .standard
    /// When embedded in a `ScrollView`, drive SwiftUI layout from measured HTML height.
    public var contentHeight: Binding<CGFloat>?
    public var onCourseFileURL: ((URL) -> Void)?

    public init(
        html: String,
        minHeight: CGFloat = 200,
        allowsInternalScrolling: Bool = false,
        variant: LearnHTMLContentVariant = .standard,
        contentHeight: Binding<CGFloat>? = nil,
        onCourseFileURL: ((URL) -> Void)? = nil
    ) {
        self.html = html
        self.minHeight = minHeight
        self.allowsInternalScrolling = allowsInternalScrolling
        self.variant = variant
        self.contentHeight = contentHeight
        self.onCourseFileURL = onCourseFileURL
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
        let wrapped = Self.document(html: html, variant: variant)
        if context.coordinator.lastLoaded != wrapped {
            context.coordinator.lastLoaded = wrapped
            contentHeight?.wrappedValue = minHeight
            webView.loadHTMLString(wrapped, baseURL: nil)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public static func document(html: String, variant: LearnHTMLContentVariant = .standard) -> String {
        let courseOverrides = variant == .course
            ? """
        body, body p, body li, body span, body div, body td, body th, body em, body strong, body u {
          color: rgba(255, 255, 255, 0.94) !important;
          background-color: transparent !important;
        }
        body a, body a.course-file-link { color: #8ea8ff !important; }
        body .course-file-missing { color: rgba(255, 255, 255, 0.55) !important; }
        body .course-imprint img { max-width: 100%; border-radius: 8px; margin: 0 0 12px 0; }
        """
            : ""
        return """
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
        \(courseOverrides)
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
            measureContentHeight(in: webView, attempt: 0)
        }

        private func measureContentHeight(in webView: WKWebView, attempt: Int) {
            webView.evaluateJavaScript("Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)") {
                [weak self] height, _ in
                guard let self else { return }
                let numeric = Self.numericHeight(height)
                let resolved = max(self.parent.minHeight, (numeric ?? self.parent.minHeight) + 8)
                if numeric == nil, attempt < 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        self.measureContentHeight(in: webView, attempt: attempt + 1)
                    }
                    return
                }
                DispatchQueue.main.async {
                    if let binding = self.parent.contentHeight {
                        binding.wrappedValue = resolved
                    } else {
                        webView.constraints.forEach { webView.removeConstraint($0) }
                        webView.heightAnchor.constraint(equalToConstant: resolved).isActive = true
                    }
                }
            }
        }

        private static func numericHeight(_ value: Any?) -> CGFloat? {
            if let number = value as? NSNumber { return CGFloat(truncating: number) }
            if let height = value as? CGFloat { return height }
            if let height = value as? Double { return CGFloat(height) }
            if let height = value as? Int { return CGFloat(height) }
            return nil
        }

        @MainActor
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else { return .allow }
            if url.scheme == "learnseqta-course-file" {
                parent.onCourseFileURL?(url)
                return .cancel
            }
            if navigationAction.navigationType == .linkActivated {
                await UIApplication.shared.open(url)
                return .cancel
            }
            return .allow
        }
    }
}
