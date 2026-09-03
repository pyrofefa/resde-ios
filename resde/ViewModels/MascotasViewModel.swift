import SwiftUI
import Combine

@MainActor
class MascotasViewModel: ObservableObject {
    @Published var perros = ""
    @Published var gatos = ""
    @Published var otrasEspecies = ""
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    func loadMascotas(ubicacionId: Int) async {
        isLoading = true
        showError = false

        do {
            guard let token = authService.token else {
                errorMessage = "No autenticado"
                showError = true
                isLoading = false
                return
            }

            let urlString = "https://resde.aseenti.com.mx/api/v1/mascotas/get?ubicacion_id=\(ubicacionId)"
            print("📍 URL Mascotas: \(urlString)")
            print("🔑 Token: \(token.prefix(20))...")

            guard let url = URL(string: urlString) else {
                errorMessage = "URL inválida"
                showError = true
                isLoading = false
                return
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "API", code: -1)
            }

            let decoder = JSONDecoder()
            let mascotasResponse = try decoder.decode(MascotasResponse.self, from: data)

            self.perros = String(mascotasResponse.no_perros)
            self.gatos = String(mascotasResponse.no_gatos)
            self.otrasEspecies = String(mascotasResponse.no_otros)
            self.isLoading = false
        } catch {
            print("❌ Error al cargar mascotas: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }

    func saveMascotas(ubicacionId: Int) async {
        isSaving = true
        showError = false

        do {
            guard let token = authService.token else {
                errorMessage = "No autenticado"
                showError = true
                isSaving = false
                return
            }

            let urlString = "https://resde.aseenti.com.mx/api/v1/mascotas/update"
            guard let url = URL(string: urlString) else { return }

            let perrosInt = Int(perros) ?? 0
            let gatosInt = Int(gatos) ?? 0
            let otrosInt = Int(otrasEspecies) ?? 0

            let body: [String: Any] = [
                "ubicacion_id": ubicacionId,
                "no_perros": perrosInt,
                "no_gatos": gatosInt,
                "no_otros": otrosInt
            ]

            let jsonData = try JSONSerialization.data(withJSONObject: body)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "API", code: -1)
            }

            isSaving = false
        } catch {
            print("❌ Error al guardar mascotas: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
            showError = true
            isSaving = false
        }
    }
}

struct MascotasResponse: Codable {
    let no_perros: Int
    let no_gatos: Int
    let no_otros: Int
}
