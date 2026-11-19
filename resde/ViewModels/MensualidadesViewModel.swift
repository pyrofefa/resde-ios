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

struct DeudaPorAnio: Decodable, Identifiable {
    var id: Int { anio }
    let anio: Int
    let totalPagado: Double
    let deudaTotal: Double

    private enum CodingKeys: String, CodingKey {
        case anio
        case totalPagado = "total_pagado"
        case deudaTotal = "deuda_total"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        anio = try c.decode(Int.self, forKey: .anio)
        totalPagado = (try? c.decode(FlexibleNumber.self, forKey: .totalPagado))?.value ?? 0
        deudaTotal = (try? c.decode(FlexibleNumber.self, forKey: .deudaTotal))?.value ?? 0
    }
}

struct DeudasPorAnioData: Decodable {
    let deudaTotalAcumulada: Double
    let deudasPorAnio: [DeudaPorAnio]

    private enum CodingKeys: String, CodingKey {
        case deudaTotalAcumulada = "deuda_total_acumulada"
        case deudasPorAnio = "deudas_por_anio"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        deudaTotalAcumulada = (try? c.decode(FlexibleNumber.self, forKey: .deudaTotalAcumulada))?.value ?? 0
        deudasPorAnio = (try? c.decode([DeudaPorAnio].self, forKey: .deudasPorAnio)) ?? []
    }
}

struct DeudasPorAnioResponse: Decodable {
    let success: Bool?
    let data: DeudasPorAnioData?
    let message: String?
}

@MainActor
class MensualidadesViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var deudaTotalAcumulada: Double = 0
    @Published var deudas: [DeudaPorAnio] = []
    @Published var errorMessage = ""
    @Published var showError = false

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    /// Un solo request con todos los años que tienen adeudos/pagos (igual que Android).
    func loadResumen(ubicacionId: Int) async {
        isLoading = true
        showError = false

        let rawData = await fetchData(endpoint: "mantenimiento/deudas-por-anio", params: ["ubicacion_id": "\(ubicacionId)"])
        if let rawData, let texto = String(data: rawData, encoding: .utf8) {
            print("📅 DEUDAS POR AÑO: \(texto)")
        }

        guard let data = rawData,
              let response = try? JSONDecoder().decode(DeudasPorAnioResponse.self, from: data),
              let info = response.data else {
            deudas = []
            deudaTotalAcumulada = 0
            errorMessage = "No se pudo cargar el estado de deuda"
            showError = true
            isLoading = false
            return
        }

        deudaTotalAcumulada = info.deudaTotalAcumulada
        deudas = info.deudasPorAnio.sorted { $0.anio > $1.anio }
        isLoading = false
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
            checkTokenInvalido(response)
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
            checkTokenInvalido(response)
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
