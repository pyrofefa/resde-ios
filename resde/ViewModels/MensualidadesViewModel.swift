import SwiftUI
import Combine

struct MensualidadItem: Codable, Identifiable {
    var id: String { "\(numero)-\(mes)" }
    let mes: String
    let numero: Int
    let cuota: Double
    let pagado: Double
    let descuento: Double
    let resta: Double
    let estatus: String
}

struct MensualidadTotales: Codable {
    let cuota: Double
    let pagado: Double
    let descuento: Double
    let resta: Double
}

struct MensualidadesData: Codable {
    let anio: Int
    let ubicacion_id: Int
    let direccion: String
    let mensualidades: [MensualidadItem]
    let totales: MensualidadTotales
}

struct MensualidadesResponse: Codable {
    let success: Bool
    let data: MensualidadesData
    let message: String
}

@MainActor
class MensualidadesViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var deudaTotalAcumulada: Double = 0
    @Published var years: [Int] = []
    @Published var totalesPorAnio: [Int: MensualidadTotales] = [:]
    @Published var errorMessage = ""
    @Published var showError = false

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    func loadResumen(ubicacionId: Int) async {
        isLoading = true
        showError = false

        let currentYear = Calendar.current.component(.year, from: Date())
        let yearsToShow = [currentYear, currentYear - 1, currentYear - 2]

        if let adeudosData = await fetchData(endpoint: "ubicaciones/estado-adeudos", params: ["ubicacion_id": "\(ubicacionId)"]) {
            if let response = try? JSONDecoder().decode(EstadoAdeudosResponse.self, from: adeudosData) {
                self.deudaTotalAcumulada = response.data?.saldoPendiente ?? 0
            }
        }

        var totales: [Int: MensualidadTotales] = [:]
        for year in yearsToShow {
            if let data = await fetchData(endpoint: "mantenimiento/mensualidades", params: ["ubicacion_id": "\(ubicacionId)", "anio": "\(year)"]) {
                if let response = try? JSONDecoder().decode(MensualidadesResponse.self, from: data) {
                    totales[year] = response.data.totales
                }
            }
        }

        self.years = yearsToShow
        self.totalesPorAnio = totales
        self.isLoading = false
    }

    private func fetchData(endpoint: String, params: [String: String]) async -> Data? {
        var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/\(endpoint)")
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 \(endpoint) Status: \(httpResponse.statusCode)")
            }
            return data
        } catch {
            print("❌ Error fetching \(endpoint): \(error)")
            return nil
        }
    }
}

@MainActor
class MensualidadesDetailViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var direccion = ""
    @Published var mensualidades: [MensualidadItem] = []
    @Published var totales: MensualidadTotales?
    @Published var errorMessage = ""
    @Published var showError = false

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    func loadMensualidades(ubicacionId: Int, anio: Int) async {
        isLoading = true
        showError = false

        var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/mantenimiento/mensualidades")
        components?.queryItems = [
            URLQueryItem(name: "ubicacion_id", value: "\(ubicacionId)"),
            URLQueryItem(name: "anio", value: "\(anio)")
        ]
        guard let url = components?.url else {
            errorMessage = "URL inválida"
            showError = true
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Mensualidades Status: \(httpResponse.statusCode)")
            }

            let decoded = try JSONDecoder().decode(MensualidadesResponse.self, from: data)
            self.direccion = decoded.data.direccion
            self.mensualidades = decoded.data.mensualidades
            self.totales = decoded.data.totales
            self.isLoading = false
        } catch {
            print("❌ Error al cargar mensualidades: \(error)")
            errorMessage = "Error al cargar mensualidades"
            showError = true
            isLoading = false
        }
    }
}
