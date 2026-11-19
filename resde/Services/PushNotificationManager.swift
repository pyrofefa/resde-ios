//
//  PushNotificationManager.swift
//  resde
//

import UIKit
import UserNotifications

extension Notification.Name {
    /// Se publica cuando el usuario toca una notificación push (abre el Historial de accesos, como Android).
    static let abrirHistorialAccesos = Notification.Name("abrirHistorialAccesos")
}

/// Pide permiso de notificaciones, registra el dispositivo en APNs y manda el token al backend
/// (`POST /devices/token`, el mismo endpoint que usa Android con `plataforma: "android"`).
final class PushNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationManager()

    private weak var authService: AuthService?
    private var deviceToken: String?
    private var ultimoRegistro: String?

    /// Hay una notificación tocada que aún no se mostró (app abierta en frío desde la notificación).
    @MainActor var abrirHistorialPendiente = false

    private override init() { super.init() }

    @MainActor
    func configurar(_ authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Permiso y registro en APNs

    @MainActor
    func solicitarPermisoYRegistrar() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let concedido = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if concedido { UIApplication.shared.registerForRemoteNotifications() }
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        default:
            break // El usuario las desactivó en Ajustes.
        }
    }

    @MainActor
    func recibioToken(_ data: Data) {
        deviceToken = data.map { String(format: "%02x", $0) }.joined()
        Task { await enviarTokenAlServidor() }
    }

    // MARK: - Envío al backend

    @MainActor
    func enviarTokenAlServidor() async {
        guard let authService, authService.isAuthenticated,
              let authToken = authService.token,
              let deviceToken else { return }

        // Evita repetir el envío del mismo token para la misma sesión.
        let registro = "\(authToken.suffix(12))-\(deviceToken)"
        guard registro != ultimoRegistro else { return }

        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/devices/token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let body: [String: Any] = [
            "token": deviceToken,
            "plataforma": "ios",
            "modelo_dispositivo": Self.modeloDispositivo(),
            "app_version": version
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("🔔 devices/token Status: \(status)")
            if (200...299).contains(status) {
                ultimoRegistro = registro
            }
        } catch {
            print("❌ Error registrando token push: \(error)")
        }
    }

    private static func modeloDispositivo() -> String {
        var info = utsname()
        uname(&info)
        let identificador = withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        return "Apple \(identificador)"
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Con la app abierta, igualmente muestra el aviso.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// Al tocar la notificación abre el Historial de accesos.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            abrirHistorialPendiente = true
            NotificationCenter.default.post(name: .abrirHistorialAccesos, object: nil)
        }
    }
}

// MARK: - AppDelegate (necesario para recibir el token de APNs en SwiftUI)

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = PushNotificationManager.shared
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationManager.shared.recibioToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ No se pudo registrar en APNs: \(error.localizedDescription)")
    }
}
