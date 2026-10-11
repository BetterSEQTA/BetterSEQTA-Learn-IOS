import Foundation
import UIKit
import UniformTypeIdentifiers

private final class LearnMessageAttachmentInteractionDelegate: NSObject, UIDocumentInteractionControllerDelegate {}

@MainActor
enum LearnMessageAttachmentPresenter {
    private static let interactionDelegate = LearnMessageAttachmentInteractionDelegate()
    private static var activeController: UIDocumentInteractionController?

    static func present(data: Data, filename: String, mimetype: String) -> Bool {
        let safeName = filename.replacingOccurrences(of: "/", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return false
        }

        let controller = UIDocumentInteractionController(url: url)
        controller.delegate = interactionDelegate
        controller.uti = uti(for: mimetype, filename: safeName)
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            return false
        }
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        activeController = controller
        return controller.presentOpenInMenu(from: presenter.view.bounds, in: presenter.view, animated: true)
    }

    private static func uti(for mimetype: String, filename: String) -> String {
        if let type = UTType(mimeType: mimetype) {
            return type.identifier
        }
        let ext = (filename as NSString).pathExtension
        if !ext.isEmpty, let type = UTType(filenameExtension: ext) {
            return type.identifier
        }
        return UTType.data.identifier
    }
}
