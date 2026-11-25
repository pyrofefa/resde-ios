import SwiftUI
import Combine

// MARK: - Modelos

struct EspecieMascota: Decodable, Identifiable, Hashable {
    let id: Int
    let descripcion: String

    private enum CodingKeys: String, CodingKey { case id, descripcion }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Int((try? c.decode(FlexibleNumber.self, forKey: .id))?.value ?? 0)
        descripcion = (try? c.decode(String.self, forKey: .descripcion)) ?? ""
    }
}

struct Mascota: Decodable, Identifiable, Equatable {
    let id: Int
    let uuid: String
    let especieId: Int
    let nombre: String
    let urlFoto: String?
    let fotoUrl: String?
    let especie: EspecieMascota?

    static func == (lhs: Mascota, rhs: Mascota) -> Bool { lhs.uuid == rhs.uuid && lhs.id == rhs.id }

    private enum CodingKeys: String, CodingKey {
        case id, uuid, nombre, especie
        case especieId = "especie_id"
        case urlFoto = "url_foto"
        case fotoUrl = "foto_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = Int((try? c.decode(FlexibleNumber.self, forKey: .id))?.value ?? 0)
        uuid = (try? c.decode(String.self, forKey: .uuid)) ?? ""
        especieId = Int((try? c.decode(FlexibleNumber.self, forKey: .especieId))?.value ?? 0)
        nombre = (try? c.decode(String.self, forKey: .nombre)) ?? ""
        urlFoto = try? c.decodeIfPresent(String.self, forKey: .urlFoto)
        fotoUrl = try? c.decodeIfPresent(String.self, forKey: .fotoUrl)
        especie = try? c.decodeIfPresent(EspecieMascota.self, forKey: .especie)
    }

    /// Misma regla que Android: `foto_url` si existe; si no, `url_foto` (relativa → /storage/).
    var urlImagen: URL? {
        if let foto = fotoUrl, !foto.isEmpty { return URL(string: foto) }
        if let relativa = urlFoto, !relativa.isEmpty {
            if relativa.hasPrefix("http") { return URL(string: relativa) }
            return URL(string: "https://resde.aseenti.com.mx/storage/\(relativa)")
        }
        return nil
    }

    var nombreEspecie: String { especie?.descripcion ?? "Especie #\(especieId)" }
}

private struct MascotasListaResponse: Decodable {
    let success: Bool?
    let mascotas: [Mascota]?
    let message: String?
}

private struct EspeciesResponse: Decodable {
    let success: Bool?
    let especies: [EspecieMascota]?
    let message: String?
}

private struct MascotaAccionResponse: Decodable {
    let success: Bool?
    let message: String?
    let errors: [String: [String]]?
}

struct ResultadoMascota {
    let exito: Bool
    let mensaje: String
}

// MARK: - ViewModel

@MainActor
class MascotasViewModel: ObservableObject {
    @Published var mascotas: [Mascota] = []
    @Published var especies: [EspecieMascota] = []
    @Published var isLoading = true
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let authService: AuthService
    private let baseURL = "https://resde.aseenti.com.mx/api/v1/"

    init() {
        self.authService = AuthService(mockData: false)
        self.authService.loadTokenFromKeychain()
    }

    // MARK: Lista

    func cargarMascotas(ubicacionId: Int) async {
        isLoading = true
        defer { isLoading = false }

        guard var components = URLComponents(string: baseURL + "mascotas/lista") else { return }
        components.queryItems = [URLQueryItem(name: "ubicacion_id", value: "\(ubicacionId)")]
        guard let url = components.url else { return }

        do {
            let (data, response) = try await URLSession.shared.data(for: solicitud(url))
            checkTokenInvalido(response, data: data)
            let decoded = try? JSONDecoder().decode(MascotasListaResponse.self, from: data)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard (200..<300).contains(status), let decoded, decoded.success != false else {
                mascotas = []
                errorMessage = decoded?.message ?? "Error al cargar datos de mascotas"
                return
            }
            mascotas = decoded.mascotas ?? []
        } catch {
            print("❌ Error al cargar mascotas: \(error)")
            mascotas = []
            errorMessage = "Error al cargar datos de mascotas"
        }
    }

    // MARK: Especies

    func cargarEspecies() async {
        guard especies.isEmpty, let url = URL(string: baseURL + "mascotas/especies") else { return }
        do {
            let (data, response) = try await URLSession.shared.data(for: solicitud(url))
            checkTokenInvalido(response, data: data)
            let decoded = try? JSONDecoder().decode(EspeciesResponse.self, from: data)
            if decoded?.success == false {
                errorMessage = decoded?.message ?? "No se pudieron cargar las especies"
            }
            especies = decoded?.especies ?? []
        } catch {
            print("❌ Error al cargar especies: \(error)")
            errorMessage = "No se pudieron cargar las especies"
        }
    }

    // MARK: Baja

    func darDeBaja(_ mascota: Mascota) async {
        guard let url = URL(string: baseURL + "mascotas/deactivate") else { return }
        isWorking = true
        defer { isWorking = false }

        var request = solicitud(url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["uuid": mascota.uuid])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response, data: data)
            let resultado = interpretar(data: data, response: response, porDefecto: "Error al dar de baja mascota")
            if resultado.exito {
                mascotas.removeAll { $0.uuid == mascota.uuid }
                successMessage = resultado.mensaje
            } else {
                errorMessage = resultado.mensaje
            }
        } catch {
            print("❌ Error al dar de baja mascota: \(error)")
            errorMessage = "Error al dar de baja mascota"
        }
    }

    // MARK: Alta / edición (multipart)

    func guardar(
        mascota: Mascota?,
        ubicacionId: Int,
        nombre: String,
        especieId: Int,
        foto: UIImage?,
        eliminarFoto: Bool
    ) async -> ResultadoMascota {
        let esEdicion = mascota != nil
        let ruta = esEdicion ? "mascotas/editar" : "mascotas/registrar"
        guard let url = URL(string: baseURL + ruta) else {
            return ResultadoMascota(exito: false, mensaje: "URL inválida")
        }

        isWorking = true
        defer { isWorking = false }

        var campos: [String: String] = [
            "ubicacion_id": "\(ubicacionId)",
            "nombre": nombre,
            "especie_id": "\(especieId)"
        ]
        if let mascota {
            if mascota.id != 0 { campos["id"] = "\(mascota.id)" }
            if !mascota.uuid.isEmpty { campos["uuid"] = mascota.uuid }
            if eliminarFoto { campos["eliminar_foto"] = "1" }
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        for (clave, valor) in campos {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(clave)\"\r\n\r\n")
            body.append("\(valor)\r\n")
        }
        if let foto, let jpeg = Self.reducida(foto).jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"foto\"; filename=\"mascota_foto.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(jpeg)
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")

        var request = solicitud(url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response, data: data)
            let resultado = interpretar(
                data: data,
                response: response,
                porDefecto: esEdicion ? "No se pudo actualizar la mascota" : "No se pudo registrar la mascota"
            )
            if resultado.exito { ImagenAutenticadaCache.shared.removeAllObjects() }
            return resultado
        } catch {
            print("❌ Error al guardar mascota: \(error)")
            return ResultadoMascota(exito: false, mensaje: "Error de red o servidor")
        }
    }

    // MARK: Helpers

    private func solicitud(_ url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func interpretar(data: Data, response: URLResponse, porDefecto: String) -> ResultadoMascota {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let decoded = try? JSONDecoder().decode(MascotaAccionResponse.self, from: data)
        let primerError = decoded?.errors?.values.first?.first
        let mensaje = primerError ?? decoded?.message ?? ""

        if (200..<300).contains(status), decoded?.success != false {
            return ResultadoMascota(exito: true, mensaje: mensaje.isEmpty ? "Operación realizada correctamente" : mensaje)
        }
        return ResultadoMascota(exito: false, mensaje: mensaje.isEmpty ? porDefecto : mensaje)
    }

    /// Evita subir fotos enormes: lado mayor máximo de 1600 px.
    private static func reducida(_ imagen: UIImage, maxLado: CGFloat = 1600) -> UIImage {
        let mayor = max(imagen.size.width, imagen.size.height)
        guard mayor > maxLado else { return imagen }
        let escala = maxLado / mayor
        let nuevo = CGSize(width: imagen.size.width * escala, height: imagen.size.height * escala)
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: nuevo, format: formato).image { _ in
            imagen.draw(in: CGRect(origin: .zero, size: nuevo))
        }
    }
}

private extension Data {
    mutating func append(_ texto: String) {
        if let datos = texto.data(using: .utf8) { append(datos) }
    }
}
