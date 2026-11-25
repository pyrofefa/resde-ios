import SwiftUI
import MapKit
import Combine

// MARK: - Modelos (GET ubicaciones/mapa)

struct ConteoMes: Decodable {
    let alCorriente: Int
    let parcial: Int
    let adeudo: Int
    let convenio: Int

    static let vacio = ConteoMes(alCorriente: 0, parcial: 0, adeudo: 0, convenio: 0)

    private enum CodingKeys: String, CodingKey {
        case alCorriente = "al_corriente"
        case parcial, adeudo, convenio
    }

    init(alCorriente: Int, parcial: Int, adeudo: Int, convenio: Int) {
        self.alCorriente = alCorriente
        self.parcial = parcial
        self.adeudo = adeudo
        self.convenio = convenio
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func entero(_ clave: CodingKeys) -> Int {
            Int((try? c.decode(FlexibleNumber.self, forKey: clave))?.value ?? 0)
        }
        alCorriente = entero(.alCorriente)
        parcial = entero(.parcial)
        adeudo = entero(.adeudo)
        convenio = entero(.convenio)
    }
}

struct UbicacionMapa: Decodable, Identifiable {
    let id: Int
    let numero: String
    let direccion: String?
    let latitud: Double?
    let longitud: Double?
    let esPropia: Bool
    let semaforo: [String: String]

    private enum CodingKeys: String, CodingKey {
        case id, numero, direccion, lat, lng, semaforo
        case esPropia = "es_propia"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Int((try? c.decode(FlexibleNumber.self, forKey: .id))?.value ?? 0)
        if let texto = try? c.decode(String.self, forKey: .numero) {
            numero = texto
        } else if let n = try? c.decode(FlexibleNumber.self, forKey: .numero) {
            numero = String(Int(n.value))
        } else {
            numero = ""
        }
        direccion = try? c.decodeIfPresent(String.self, forKey: .direccion)
        latitud = (try? c.decodeIfPresent(FlexibleNumber.self, forKey: .lat))?.value
        longitud = (try? c.decodeIfPresent(FlexibleNumber.self, forKey: .lng))?.value
        if let b = try? c.decode(Bool.self, forKey: .esPropia) {
            esPropia = b
        } else if let n = try? c.decode(FlexibleNumber.self, forKey: .esPropia) {
            esPropia = n.value != 0
        } else {
            esPropia = false
        }
        semaforo = (try? c.decode([String: String].self, forKey: .semaforo)) ?? [:]
    }

    /// Coordenada válida (descarta nulos y 0,0).
    var coordenada: CLLocationCoordinate2D? {
        guard let lat = latitud, let lng = longitud,
              (-90...90).contains(lat), (-180...180).contains(lng),
              !(lat == 0 && lng == 0) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    func estado(mes: Int) -> EstadoSemaforo {
        EstadoSemaforo(rawValue: semaforo["\(mes)"] ?? "") ?? .adeudo
    }
}

/// Estado de pago de una vivienda en un mes (desconocido → adeudo, como Android).
enum EstadoSemaforo: String {
    case alCorriente = "al_corriente"
    case parcial
    case convenio
    case adeudo

    var color: Color {
        switch self {
        case .alCorriente: return Color(.sRGB, red: 0x16 / 255, green: 0xA3 / 255, blue: 0x4A / 255, opacity: 1) // #16A34A
        case .parcial: return Color(.sRGB, red: 0xEA / 255, green: 0xB3 / 255, blue: 0x08 / 255, opacity: 1)     // #EAB308
        case .convenio: return Color(.sRGB, red: 0x93 / 255, green: 0x33 / 255, blue: 0xEA / 255, opacity: 1)    // #9333EA
        case .adeudo: return Color(.sRGB, red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255, opacity: 1)      // #EF4444
        }
    }
}

struct MapaData: Decodable {
    let anio: Int
    let aniosDisponibles: [Int]
    let centro: CLLocationCoordinate2D?
    let conteosPorMes: [String: ConteoMes]
    let ubicaciones: [UbicacionMapa]

    private enum CodingKeys: String, CodingKey {
        case anio, center, ubicaciones
        case aniosDisponibles = "anios_disponibles"
        case conteosPorMes = "conteos_por_mes"
    }

    private struct Centro: Decodable {
        let lat: Double
        let lng: Double
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        anio = Int((try? c.decode(FlexibleNumber.self, forKey: .anio))?.value ?? 0)
        aniosDisponibles = (try? c.decode([Int].self, forKey: .aniosDisponibles)) ?? []
        if let centro = try? c.decodeIfPresent(Centro.self, forKey: .center) {
            self.centro = CLLocationCoordinate2D(latitude: centro.lat, longitude: centro.lng)
        } else {
            self.centro = nil
        }
        conteosPorMes = (try? c.decode([String: ConteoMes].self, forKey: .conteosPorMes)) ?? [:]
        ubicaciones = (try? c.decode([UbicacionMapa].self, forKey: .ubicaciones)) ?? []
    }
}

private struct MapaResponse: Decodable {
    let success: Bool?
    let message: String?
    let data: MapaData?
}

// MARK: - ViewModel

@MainActor
class MapaResidencialViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var data: MapaData?
    @Published var anioSeleccionado: Int?
    @Published var errorMessage: String?

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    var aniosDisponibles: [Int] {
        let anios = data?.aniosDisponibles ?? []
        if anios.isEmpty, let actual = anioSeleccionado { return [actual] }
        return anios.sorted(by: >)
    }

    func conteos(mes: Int) -> ConteoMes {
        data?.conteosPorMes["\(mes)"] ?? .vacio
    }

    /// Carga el mapa. Con `anio == nil` el servidor elige el año activo.
    /// Devuelve true si se cargó correctamente.
    @discardableResult
    func cargar(anio: Int?) async -> Bool {
        guard var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/ubicaciones/mapa") else {
            return false
        }
        if let anio { components.queryItems = [URLQueryItem(name: "anio", value: "\(anio)")] }
        guard let url = components.url else { return false }

        isLoading = true
        defer { isLoading = false }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (datos, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let decoded = try? JSONDecoder().decode(MapaResponse.self, from: datos)

            guard (200..<300).contains(status), decoded?.success != false, let info = decoded?.data else {
                errorMessage = decoded?.message ?? "Error al cargar mapa"
                return false
            }
            data = info
            anioSeleccionado = info.anio
            return true
        } catch {
            print("❌ Error al cargar mapa: \(error)")
            errorMessage = "Error de conexión al cargar mapa"
            return false
        }
    }
}
