@preconcurrency import AVFoundation
import CoreDesign
import SwiftUI

struct LearnQRCodeScannerView: View {
    let onCodeScanned: (String) -> Void

    @State private var cameraAuthorized = false
    @State private var permissionDenied = false

    var body: some View {
        Group {
            if permissionDenied {
                VStack(spacing: LearnTheme.Spacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    Text("Camera access is required to scan QR codes. Enable it in Settings.")
                        .font(.footnote)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else if cameraAuthorized {
                LearnQRCodeScannerRepresentable(onCodeScanned: onCodeScanned)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            }
        }
        .task { await requestCameraAccess() }
    }

    private func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorized = granted
            permissionDenied = !granted
        default:
            permissionDenied = true
        }
    }
}

private struct LearnQRCodeScannerRepresentable: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .black

        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return container
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return container }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        container.layer.addSublayer(preview)

        context.coordinator.previewLayer = preview
        context.coordinator.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.captureSession?.stopRunning()
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureSession: AVCaptureSession?
        private var didEmit = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !didEmit,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue,
                  !value.isEmpty else { return }
            didEmit = true
            captureSession?.stopRunning()
            onCodeScanned(value)
        }
    }
}
