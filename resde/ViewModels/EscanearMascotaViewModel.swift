import SwiftUI
import Combine

// MARK: - Modelos

struct MascotaQr: Decodable {
    let uuid: String
    let nombre: String
    let especie: String?
    let especieId: Int?
    let fotoUrl: String?
    let calle: String?
    let numero: String?
    let direccion: String?
    let residencialNombre: String?
    let residencialCode: String?

    private enum CodingKeys: String, CodingKey {
        case uuid, nombre, especie, calle, numero, direccion, residencial
        case especieId = "especie_id"
        case fotoUrl = "foto_url"
    }

    private struct ResidencialQr: Decodable {
        let nombre: String?
        let code: String?
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid = (try? c.decode(String.self, forKey: .uuid)) ?? ""
        nombre = (try? c.decode(String.self, forKey: .nombre)) ?? ""
        especie = try? c.decodeIfPresent(String.self, forKey: .especie)
        especieId = (try? c.decode(FlexibleNumber.self, forKey: .especieId)).map { Int($0.value) }
        fotoUrl = try? c.decodeIfPresent(String.self, forKey: .fotoUrl)
        calle = try? c.decodeIfPresent(String.self, forKey: .calle)
        direccion = try? c.decodeIfPresent(String.self, forKey: .direccion)
        // `numero` puede llegar como texto o como número.
        if let texto = try? c.decodeIfPresent(String.self, forKey: .numero) {
            numero = texto
        } else if let n = try? c.decode(FlexibleNumber.self, forKey: .numero) {
            numero = String(Int(n.value))
        } else {
            numero = nil
        }
        let residencial = try? c.decodeIfPresent(ResidencialQr.self, forKey: .residencial)
        residencialNombre = residencial?.nombre
        residencialCode = residencial?.code
    }

    var textoEspecie: String {
        if let especie, !especie.isEmpty { return especie }
        if let especieId { return "Especie #\(especieId)" }
        return "Mascota"
    }

    var textoDireccion: String {
        if let direccion, !direccion.isEmpty { return direccion }
        return "\(calle ?? "") #\(numero ?? "")"
    }

    var textoResidencial: String {
        "\(residencialNombre ?? "Residencial") (\(residencialCode ?? ""))"
    }

    var urlFoto: URL? {
        guard let fotoUrl, !fotoUrl.isEmpty else { return nil }
        return URL(string: fotoUrl)
    }
}

private struct MascotaQrRespuesta: Decodable {
    let success: Bool?
    let mascota: MascotaQr?
    let message: String?
    let errors: [String: [String]]?
}

enum ResultadoQr {
    case encontrada(MascotaQr)
    case aviso(String)
}

// MARK: - ViewModel

@MainActor
class EscanearMascotaViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var mascota: MascotaQr?

    private let authService: AuthService

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    static let mensajeNoEncontrada = "No se encontró ninguna mascota activa con ese código QR."

    /// Consulta `GET mascotas/qr?codigo=` y devuelve la mascota o el aviso a mostrar.
    func consultar(codigo: String) async -> ResultadoQr {
        let limpio = codigo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/mascotas/qr") else {
            return .aviso("Error en el servidor")
        }
        components.queryItems = [URLQueryItem(name: "codigo", value: limpio)]
        guard let url = components.url else { return .aviso("Formato de QR inválido") }

        isLoading = true
        mascota = nil
        defer { isLoading = false }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let decoded = try? JSONDecoder().decode(MascotaQrRespuesta.self, from: data)

            if (200..<300).contains(status), decoded?.success != false, let encontrada = decoded?.mascota {
                mascota = encontrada
                return .encontrada(encontrada)
            }

            let crudo = decoded?.errors?["codigo"]?.first ?? decoded?.message ?? ""
            return .aviso(traducir(mensaje: crudo, status: status))
        } catch {
            print("❌ Error al identificar mascota: \(error)")
            return .aviso("Error de red o servidor")
        }
    }

    private func traducir(mensaje: String, status: Int) -> String {
        let minusculas = mensaje.lowercased()
        if status == 404 || minusculas.contains("no se encontr") || minusculas.contains("not found") {
            return Self.mensajeNoEncontrada
        }
        if status == 422 || minusculas.contains("formato") || minusculas.contains("inválid") {
            return "Formato de QR inválido"
        }
        if status == 401 || minusculas.contains("unauthenticated") {
            return "Sesión expirada"
        }
        return mensaje.isEmpty ? "Error en el servidor" : mensaje
    }
}
