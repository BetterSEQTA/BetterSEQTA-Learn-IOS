@preconcurrency import AVFoundation
import CoreDesign
import SwiftUI

struct LearnQRCodeScannerView: View {
    let onCodeScanned: (String) -> Void

    @State private var cameraAuthorized = false
    @State private var permissionDenied = false
    @State private var scannerGeneration = 0

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
                    .id(scannerGeneration)
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: LearnTheme.controlCornerRadius))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            }
        }
        .onAppear {
            Task { await requestCameraAccess() }
        }
    }

    private func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
            scannerGeneration += 1
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorized = granted
            permissionDenied = !granted
            if granted { scannerGeneration += 1 }
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

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        context.coordinator.attach(to: uiView)
    }

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private weak var previewView: CameraPreviewView?
        private var didEmit = false
        private var isConfigured = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func attach(to view: CameraPreviewView) {
            previewView = view
            guard !isConfigured else {
                previewLayer?.frame = view.bounds
                startSessionIfNeeded()
                return
            }
            configureSession(on: view)
        }

        func teardown() {
            captureSession?.stopRunning()
            previewLayer?.removeFromSuperlayer()
            captureSession = nil
            previewLayer = nil
            isConfigured = false
        }

        private func configureSession(on view: CameraPreviewView) {
            let session = AVCaptureSession()
            session.sessionPreset = .high
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            view.previewLayer = preview
            view.layer.addSublayer(preview)

            captureSession = session
            previewLayer = preview
            isConfigured = true
            preview.frame = view.bounds
            startSessionIfNeeded()
        }

        private func startSessionIfNeeded() {
            guard let session = captureSession, !session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
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

private final class CameraPreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
