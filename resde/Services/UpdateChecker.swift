//
//  UpdateChecker.swift
//  resde
//

import Foundation

struct ActualizacionDisponible {
    let version: String
    let url: URL
}

/// Avisa cuando hay una versión más nueva en la App Store (equivalente al aviso de
/// actualización de Google Play que tiene Android). Usa la API pública de búsqueda de iTunes.
@MainActor
enum UpdateChecker {
    private static var revisadoEnEstaSesion = false
    private static let versionAvisadaKey = "updateVersionAvisada"
    private static let fechaAvisoKey = "updateFechaAviso"

    /// Devuelve la actualización disponible, o nil si no hay, si ya se revisó en esta sesión
    /// o si esa misma versión ya se avisó en las últimas 24 horas.
    static func buscarActualizacion() async -> ActualizacionDisponible? {
        guard !revisadoEnEstaSesion else { return nil }
        revisadoEnEstaSesion = true

        guard let instalada = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let bundleId = Bundle.main.bundleIdentifier else { return nil }

        // La app se distribuye en México; sin país la búsqueda usa la tienda de EE. UU.
        for pais in ["mx", nil] as [String?] {
            guard let tienda = await consultarTienda(bundleId: bundleId, pais: pais) else { continue }
            guard esMayor(tienda.version, que: instalada) else { return nil }
            guard !yaSeAvisoRecientemente(version: tienda.version) else { return nil }
            registrarAviso(version: tienda.version)
            return tienda
        }
        return nil
    }

    // MARK: - Consulta

    private static func consultarTienda(bundleId: String, pais: String?) async -> ActualizacionDisponible? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var items = [URLQueryItem(name: "bundleId", value: bundleId)]
        if let pais { items.append(URLQueryItem(name: "country", value: pais)) }
        components?.queryItems = items
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let resultados = json["results"] as? [[String: Any]],
                  let primero = resultados.first,
                  let version = primero["version"] as? String,
                  let vista = primero["trackViewUrl"] as? String,
                  let urlTienda = URL(string: vista) else { return nil }
            return ActualizacionDisponible(version: version, url: urlTienda)
        } catch {
            print("❌ Error consultando versión en la App Store: \(error)")
            return nil
        }
    }

    // MARK: - Versiones

    /// Compara versiones numéricas tipo "1.0.10" > "1.0.9".
    private static func esMayor(_ a: String, que b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }
        let y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0
            let q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }

    // MARK: - Para no insistir

    private static func yaSeAvisoRecientemente(version: String) -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: versionAvisadaKey) == version,
              let fecha = defaults.object(forKey: fechaAvisoKey) as? Date else { return false }
        return Date().timeIntervalSince(fecha) < 24 * 3600
    }

    private static func registrarAviso(version: String) {
        let defaults = UserDefaults.standard
        defaults.set(version, forKey: versionAvisadaKey)
        defaults.set(Date(), forKey: fechaAvisoKey)
    }
}
