import SwiftUI
import AVFoundation

/// Escáner de códigos QR con la cámara trasera (AVFoundation).
/// Entrega el primer código leído una sola vez.
struct QRScannerView: UIViewControllerRepresentable {
    let onCodigo: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodigo = onCodigo
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodigo: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private let session = AVCaptureSession()
    private let colaSesion = DispatchQueue(label: "mx.aseenti.resde.qr-session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var yaLeyo = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        colaSesion.async { [session] in
            if !session.isRunning { session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        colaSesion.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configurar() {
        guard let dispositivo = AVCaptureDevice.default(for: .video),
              let entrada = try? AVCaptureDeviceInput(device: dispositivo),
              session.canAddInput(entrada) else {
            onError?("Este dispositivo no tiene una cámara disponible para escanear.")
            return
        }
        session.addInput(entrada)

        let salida = AVCaptureMetadataOutput()
        guard session.canAddOutput(salida) else {
            onError?("No se pudo iniciar el lector de códigos QR.")
            return
        }
        session.addOutput(salida)
        salida.setMetadataObjectsDelegate(self, queue: .main)
        salida.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !yaLeyo,
              let objeto = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let valor = objeto.stringValue, !valor.isEmpty else { return }
        yaLeyo = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        colaSesion.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
        onCodigo?(valor)
    }
}
