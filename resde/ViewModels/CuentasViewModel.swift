import SwiftUI
import Combine

@MainActor
class CuentasViewModel: ObservableObject {
    @Published var cuentas: [Cuenta] = []
    @Published var searchText = ""
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var selectedCuenta: Cuenta?

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        authService.loadTokenFromKeychain()
    }

    var filteredCuentas: [Cuenta] {
        if searchText.isEmpty {
            return cuentas
        }
        return cuentas.filter { $0.nombre_completo.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadCuentas(ubicacionId: Int) async {
        isLoading = true
        showError = false

        do {
            guard let token = authService.token else {
                errorMessage = "No autenticado"
                showError = true
                isLoading = false
                return
            }

            let urlString = "https://resde.aseenti.com.mx/api/v1/vinculados?ubicacion_id=\(ubicacionId)"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response, data: data)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "API", code: -1)
            }

            print("📊 Cuentas Status: \(httpResponse.statusCode)")

            if let jsonStr = String(data: data, encoding: .utf8) {
                print("📄 Cuentas Response: \(jsonStr.prefix(300))")
            }

            guard httpResponse.statusCode == 200 else {
                throw NSError(domain: "API", code: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            let cuentasResponse = try decoder.decode(CuentasResponse.self, from: data)
            self.cuentas = cuentasResponse.data
            self.isLoading = false
        } catch {
            print("❌ Error al cargar cuentas: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
}

struct Cuenta: Codable, Identifiable {
    let id: Int
    let nombre: String
    let apellido_paterno: String?
    let apellido_materno: String?
    let email: String
    let telefono: String?
    let status: Int
    let nombre_completo: String
    let renta: Int
    let renta_texto: String

    var correo: String { email }
    var estado: String { status == 1 ? "Activo" : "Inactivo" }
    var ubicacion: String { "" }
}

struct CuentasResponse: Codable {
    let data: [Cuenta]
}

// MARK: - Gestión de vinculados (alta, edición, contraseña, estatus)

struct ResultadoAccion {
    let exito: Bool
    let mensaje: String
}

struct PermisoVinculado: Decodable, Identifiable {
    let id: Int
    let nombre: String
    let asignado: Bool?
}

private struct PermisosVinculadoResponse: Decodable {
    let data: [PermisoVinculado]?
}

extension CuentasViewModel {
    /// Catálogo de permisos disponibles (para dar de alta una cuenta).
    func cargarPermisos() async -> [PermisoVinculado] {
        let r = await peticion("GET", "vinculados/permisos")
        guard let data = r.data,
              let response = try? JSONDecoder().decode(PermisosVinculadoResponse.self, from: data) else { return [] }
        return response.data ?? []
    }

    /// Permisos de un usuario; `asignado` indica los que ya tiene.
    func cargarPermisosUsuario(userId: Int) async -> [PermisoVinculado] {
        let r = await peticion("GET", "vinculados/permisos-usuario", query: ["user_id": "\(userId)"])
        guard let data = r.data,
              let response = try? JSONDecoder().decode(PermisosVinculadoResponse.self, from: data) else { return [] }
        return response.data ?? []
    }

    func crearCuenta(_ params: [String: Any]) async -> ResultadoAccion {
        await accion("POST", "vinculados/store", body: params, exitoPorDefecto: "Cuenta vinculada creada correctamente", errorPorDefecto: "Error al procesar el registro")
    }

    func actualizarCuenta(id: Int, _ params: [String: Any]) async -> ResultadoAccion {
        await accion("PUT", "vinculados/\(id)", body: params, exitoPorDefecto: "Cuenta actualizada correctamente", errorPorDefecto: "Error al actualizar la cuenta")
    }

    func cambiarPassword(id: Int, password: String, confirmacion: String) async -> ResultadoAccion {
        await accion("PUT", "vinculados/\(id)/password",
                     body: ["password": password, "password_confirmation": confirmacion],
                     exitoPorDefecto: "Contraseña actualizada correctamente", errorPorDefecto: "Error al actualizar la contraseña")
    }

    func cambiarEstatus(id: Int) async -> ResultadoAccion {
        await accion("POST", "vinculados/\(id)/toggle-status", body: nil, exitoPorDefecto: "Estatus actualizado correctamente", errorPorDefecto: "Error al cambiar el estatus de la cuenta")
    }

    // MARK: - Helpers

    private func peticion(_ method: String, _ path: String, query: [String: String] = [:], body: [String: Any]? = nil) async -> (data: Data?, status: Int) {
        guard let token = authService.token else { return (nil, 0) }

        var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/\(path)")
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { return (nil, 0) }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response, data: data)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("👥 \(method) \(path) Status: \(status)")
            return (data, status)
        } catch {
            print("❌ Error \(method) \(path): \(error)")
            return (nil, 0)
        }
    }

    private func accion(_ method: String, _ path: String, body: [String: Any]?, exitoPorDefecto: String, errorPorDefecto: String) async -> ResultadoAccion {
        let r = await peticion(method, path, body: body)
        guard let data = r.data else {
            return ResultadoAccion(exito: false, mensaje: "Error de conexión o servidor")
        }

        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let mensaje = json?["message"] as? String

        if (200...299).contains(r.status), (json?["success"] as? Bool) != false {
            return ResultadoAccion(exito: true, mensaje: mensaje ?? exitoPorDefecto)
        }

        // Errores de validación de Laravel: { "errors": { "campo": ["mensaje"] } }
        if let errors = json?["errors"] as? [String: Any],
           let primero = errors.values.compactMap({ ($0 as? [String])?.first }).first {
            return ResultadoAccion(exito: false, mensaje: primero)
        }
        return ResultadoAccion(exito: false, mensaje: mensaje ?? errorPorDefecto)
    }
}
