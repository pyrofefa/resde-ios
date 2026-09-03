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
