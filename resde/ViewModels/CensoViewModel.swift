import SwiftUI
import Combine

@MainActor
class CensoViewModel: ObservableObject {
    @Published var residentes = ""
    @Published var menores = ""
    @Published var adultosMayores = ""
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let authService = AuthService(mockData: false)

    init() {
        authService.loadTokenFromKeychain()
    }

    func loadCenso(ubicacionId: String) async {
        isLoading = true
        showError = false

        if let data = await fetchCenso(ubicacionId: ubicacionId) {
            do {
                let response = try JSONDecoder().decode(CensoResponse.self, from: data)
                await MainActor.run {
                    self.residentes = String(response.numero_residentes ?? 0)
                    self.menores = String(response.numero_menores ?? 0)
                    self.adultosMayores = String(response.numero_mayores ?? 0)
                    self.isLoading = false
                }
            } catch {
                print("❌ Error decodificando censo: \(error)")
                await MainActor.run {
                    self.errorMessage = "Error al cargar censo: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        } else {
            await MainActor.run {
                self.errorMessage = "Error al conectar con el servidor"
                self.showError = true
                self.isLoading = false
            }
        }
    }

    func saveCenso(ubicacionId: String) async {
        isSaving = true
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/censo/update") else {
            await MainActor.run {
                errorMessage = "URL inválida"
                showError = true
                isSaving = false
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "ubicacion_id": ubicacionId,
            "total_residentes": Int(residentes) ?? 0,
            "menores": Int(menores) ?? 0,
            "adultos_mayores": Int(adultosMayores) ?? 0
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    await MainActor.run {
                        isSaving = false
                    }
                } else {
                    await MainActor.run {
                        isSaving = false
                        errorMessage = "Error al guardar censo"
                        showError = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func fetchCenso(ubicacionId: String) async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/ubicaciones/censo?ubicacion_id=\(ubicacionId)") else {
            return nil
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Censo Status: \(httpResponse.statusCode)")
            }
            if let jsonStr = String(data: data, encoding: .utf8) {
                print("📄 Censo Response: \(jsonStr.prefix(200))")
            }
            return data
        } catch {
            print("❌ Error fetching censo: \(error)")
            return nil
        }
    }
}
