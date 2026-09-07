import SwiftUI
import Combine

@MainActor
class VehiculosViewModel: ObservableObject {
    @Published var vehiculos: [VehiculoForm] = Array(repeating: VehiculoForm(), count: 4)
    @Published var brands: [Brand] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    func loadVehiculos(ubicacionId: Int) async {
        isLoading = true
        showError = false

        do {
            guard let token = authService.token else {
                errorMessage = "No autenticado"
                showError = true
                isLoading = false
                return
            }

            let urlString = "https://resde.aseenti.com.mx/api/v1/vehiculos/reload?ubicacion_id=\(ubicacionId)"
            print("📍 URL Vehículos: \(urlString)")
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
            checkTokenInvalido(response)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "API", code: -1)
            }

            if let jsonStr = String(data: data, encoding: .utf8) {
                print("📄 JSON Response: \(jsonStr)")
            }

            let decoder = JSONDecoder()
            let vehiculosResponse = try decoder.decode(VehiculosResponse.self, from: data)

            self.brands = vehiculosResponse.brands
            print("📦 Brands recibidos: \(self.brands.count) marcas")
            if let firstBrand = self.brands.first {
                print("🏷️ First brand: id=\(firstBrand.id), descripcion=\(firstBrand.descripcion)")
            }

            if let vehicle = vehiculosResponse.vehicles.first {
                vehiculos[0].marcaAutoId = vehicle.marca_auto_id
                vehiculos[0].color = vehicle.color ?? ""
                vehiculos[0].placa = vehicle.placa ?? ""

                vehiculos[1].marcaAutoId = vehicle.marca_auto_id_2
                vehiculos[1].color = vehicle.color_2 ?? ""
                vehiculos[1].placa = vehicle.placa_2 ?? ""

                vehiculos[2].marcaAutoId = vehicle.marca_auto_id_3
                vehiculos[2].color = vehicle.color_3 ?? ""
                vehiculos[2].placa = vehicle.placa_3 ?? ""

                vehiculos[3].marcaAutoId = vehicle.marca_auto_id_4
                vehiculos[3].color = vehicle.color_4 ?? ""
                vehiculos[3].placa = vehicle.placa_4 ?? ""
            }

            isLoading = false
        } catch {
            print("❌ Error al cargar vehículos: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }

    func saveVehiculos(ubicacionId: Int) async {
        isSaving = true
        showError = false

        do {
            guard let token = authService.token else {
                errorMessage = "No autenticado"
                showError = true
                isSaving = false
                return
            }

            let urlString = "https://resde.aseenti.com.mx/api/v1/vehiculos/store"
            guard let url = URL(string: urlString) else { return }

            var body: [String: Any] = ["ubicacion_id": ubicacionId]

            for (index, vehiculo) in vehiculos.enumerated() {
                let suffix = index == 0 ? "" : "_\(index + 1)"
                body["marca_auto_id\(suffix)"] = vehiculo.marcaAutoId as Any
                body["color\(suffix)"] = vehiculo.color.isEmpty ? NSNull() : vehiculo.color
                body["placa\(suffix)"] = vehiculo.placa.isEmpty ? NSNull() : vehiculo.placa
            }

            let jsonData = try JSONSerialization.data(withJSONObject: body)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "API", code: -1)
            }

            isSaving = false
        } catch {
            print("❌ Error al guardar vehículos: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
            showError = true
            isSaving = false
        }
    }
}

struct VehiculoForm: Identifiable {
    let id = UUID()
    var marcaAutoId: Int?
    var color: String = ""
    var placa: String = ""
}

struct Brand: Codable {
    let id: Int
    let descripcion: String

    enum CodingKeys: String, CodingKey {
        case id
        case descripcion
    }
}

struct Vehicle: Codable {
    let marca_auto_id: Int?
    let color: String?
    let placa: String?
    let marca_auto_id_2: Int?
    let color_2: String?
    let placa_2: String?
    let marca_auto_id_3: Int?
    let color_3: String?
    let placa_3: String?
    let marca_auto_id_4: Int?
    let color_4: String?
    let placa_4: String?
}

struct VehiculosResponse: Codable {
    let success: Bool
    let vehicles: [Vehicle]
    let brands: [Brand]
}
