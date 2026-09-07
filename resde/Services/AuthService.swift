//
//  AuthService.swift
//  resde
//

import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: AuthData?
    @Published var token: String?
    @Published var errorMessage: String?
    @Published var isLoading = false

    @Published var carouselData: CarouselData = CarouselData()

    private let baseURL = "https://resde.aseenti.com.mx/api/v1"

    init(mockData: Bool = false) {
        if mockData {
            setupMockData()
        }
    }

    private func setupMockData() {
        self.token = "mock_token_123456"
        self.user = AuthData(
            id: 1,
            first_name: "Juan",
            last_name: "Pérez",
            residencial_id: 1,
            residencial: "Residencial San Juan",
            logo: "logoApp",
            is_super_admin: false,
            ubicaciones: [
                "1": "Juan Rulfo #11",
                "2": "Calle Principal #100",
                "3": "Avenida Central #50"
            ],
            roles: ["resident"],
            permissions: [
                "pago.create",
                "cuentasv.manage",
                "evento.manage",
                "queja.manage",
                "reporte.view",
                "vehiculos.manage",
                "mascotas.manage",
                "censo.manage",
                "tarjetas.manage"
            ]
        )
        self.isAuthenticated = true
    }

    func login(email: String, password: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        let loginRequest = LoginRequest(email: email, password: password)

        guard let url = URL(string: "\(baseURL)/login") else {
            await MainActor.run {
                self.errorMessage = "URL inválida"
                self.isLoading = false
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var responseData: Data?

        do {
            request.httpBody = try JSONEncoder().encode(loginRequest)

            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data

            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.errorMessage = "Respuesta inválida del servidor"
                }
                return
            }

            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                let authResponse = try decoder.decode(AuthResponse.self, from: data)

                await MainActor.run {
                    self.isAuthenticated = true
                    self.user = authResponse.data
                    self.token = authResponse.accessToken
                    self.errorMessage = nil
                    self.isLoading = false
                    saveToken(authResponse.accessToken)
                    UserDefaults.standard.set(try? JSONEncoder().encode(authResponse.data), forKey: "currentUser")
                }

            case 401:
                await MainActor.run {
                    self.errorMessage = "Email o contraseña incorrectos"
                    self.isLoading = false
                }

            case 400:
                let errorMessage = parseErrorResponse(data)
                await MainActor.run {
                    self.errorMessage = errorMessage
                    self.isLoading = false
                }

            default:
                await MainActor.run {
                    self.errorMessage = "Error del servidor. Intenta más tarde."
                    self.isLoading = false
                }
            }

        } catch let error as DecodingError {
            let responseString = responseData.map { String(data: $0, encoding: .utf8) ?? "No readable" } ?? "No data"
            print("❌ Decoding Error: \(error)")
            print("📝 Response: \(responseString)")
            await MainActor.run {
                self.errorMessage = "Error al procesar la respuesta del servidor"
                self.isLoading = false
            }
        } catch {
            print("❌ Connection Error: \(error)")
            await MainActor.run {
                self.errorMessage = "Error de conexión: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func logout() {
        isAuthenticated = false
        user = nil
        token = nil
        errorMessage = nil
        deleteToken()
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    private func saveToken(_ token: String) {
        let keychain = KeychainHelper()
        keychain.save(token, forKey: "authToken")
    }

    private func deleteToken() {
        let keychain = KeychainHelper()
        keychain.delete(key: "authToken")
    }

    func loadTokenFromKeychain() {
        let keychain = KeychainHelper()
        if let token = keychain.get(key: "authToken") {
            self.token = token
            self.isAuthenticated = true

            if let userData = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(AuthData.self, from: userData) {
                self.user = user
            }
        }
    }

    func loadCarouselDataInParallel(ubicacionId: String) async {
        async let estadoAdeudos = fetchCarouselData(endpoint: "ubicaciones/estado-adeudos", params: ["ubicacion_id": ubicacionId])
        async let censo = fetchCarouselData(endpoint: "ubicaciones/censo", params: ["ubicacion_id": ubicacionId])
        async let mascotas = fetchCarouselData(endpoint: "ubicaciones/mascotas", params: ["ubicacion_id": ubicacionId])
        async let vehiculos = fetchCarouselData(endpoint: "ubicaciones/vehiculos", params: ["ubicacion_id": ubicacionId])
        async let tarjetas = fetchCarouselData(endpoint: "ubicaciones/tarjetas", params: ["ubicacion_id": ubicacionId])
        async let eventos = fetchCarouselData(endpoint: "ubicaciones/eventos-activos-pagados", params: ["ubicacion_id": ubicacionId])

        let (estadoAdeudosData, censoData, mascotasData, vehiculosData, tarjetasData, eventosData) = await (estadoAdeudos, censo, mascotas, vehiculos, tarjetas, eventos)

        if let estadoAdeudosData = estadoAdeudosData, let str = String(data: estadoAdeudosData, encoding: .utf8) {
            print("💳 ESTADO ADEUDOS: \(str)")
        }
        if let censoData = censoData, let censoStr = String(data: censoData, encoding: .utf8) {
            print("📊 CENSO: \(censoStr)")
        }
        if let mascotasData = mascotasData, let mascotasStr = String(data: mascotasData, encoding: .utf8) {
            print("🐾 MASCOTAS: \(mascotasStr)")
        }
        if let vehiculosData = vehiculosData, let vehiculosStr = String(data: vehiculosData, encoding: .utf8) {
            print("🚗 VEHÍCULOS: \(vehiculosStr)")
        }
        if let tarjetasData = tarjetasData, let tarjetasStr = String(data: tarjetasData, encoding: .utf8) {
            print("🎫 TARJETAS: \(tarjetasStr)")
        }
        if let eventosData = eventosData, let eventosStr = String(data: eventosData, encoding: .utf8) {
            print("📅 EVENTOS: \(eventosStr)")
        }

        await MainActor.run {
            self.carouselData = CarouselData(
                estadoAdeudos: parseCarouselResponse(estadoAdeudosData, type: EstadoAdeudosResponse.self),
                censo: parseCarouselResponse(censoData, type: CensoResponse.self),
                mascotas: parseCarouselResponse(mascotasData, type: CarouselMascotasResponse.self),
                vehiculos: parseCarouselResponse(vehiculosData, type: CarouselVehiculosResponse.self),
                tarjetas: parseCarouselResponse(tarjetasData, type: TarjetasResponse.self),
                eventos: parseCarouselResponse(eventosData, type: EventosResponse.self)
            )
        }
    }

    private func parseCarouselResponse<T: Decodable>(_ data: Data?, type: T.Type) -> T? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func fetchCarouselData(endpoint: String, params: [String: String]) async -> Data? {
        guard let url = buildURL(endpoint: endpoint, params: params) else { return nil }

        var request = URLRequest(url: url)
        print("🌐 URL: \(url.absoluteString)")
        print("🔑 Token: \(self.token ?? "NIL")")

        if let token = self.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ Authorization header set")
        } else {
            print("❌ No token available")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Status code: \(httpResponse.statusCode)")
            }
            return data
        } catch {
            print("Error fetching \(endpoint): \(error)")
            return nil
        }
    }

    private func buildURL(endpoint: String, params: [String: String]) -> URL? {
        var components = URLComponents(string: "\(baseURL)/\(endpoint)")
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url
    }

    private func parseErrorResponse(_ data: Data) -> String {
        if let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
            return errorResponse.msj
        }

        if let errorDict = try? JSONDecoder().decode([String: String].self, from: data) {
            return errorDict["msj"] ?? errorDict["message"] ?? "Datos inválidos"
        }

        if let errorString = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
            if let message = errorString["msj"]?.value as? String {
                return message
            }
        }

        return "Datos inválidos"
    }
}

extension Notification.Name {
    /// Se dispara cuando cualquier llamada a la API responde 401 (token inválido/expirado).
    static let tokenInvalido = Notification.Name("TokenInvalido")
}

/// Revisa la respuesta de una llamada a la API; si es 401, notifica para que la sesión se cierre.
/// Debe llamarse justo después de cada `URLSession.shared.data(for:)` que use el Bearer token.
func checkTokenInvalido(_ response: URLResponse?) {
    guard let httpResponse = response as? HTTPURLResponse else { return }

    // Algunos endpoints responden 401/419 en JSON; otros, cuando el token es
    // inválido, terminan redirigiendo (302 → 200) a la página HTML de login
    // en vez de devolver un error de API. Detectamos ambos casos.
    let redirigioALogin = httpResponse.url?.path.contains("/login") == true
    let statusInvalido = httpResponse.statusCode == 401 || httpResponse.statusCode == 419

    if statusInvalido || redirigioALogin {
        print("🔒 Token inválido/expirado (\(httpResponse.statusCode)\(redirigioALogin ? ", redirigido a /login" : "")) — cerrando sesión")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .tokenInvalido, object: nil)
        }
    }
}

private enum AnyCodable: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    var value: Any {
        switch self {
        case .string(let str): return str
        case .int(let num): return num
        case .double(let num): return num
        case .bool(let bool): return bool
        case .null: return NSNull()
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let str): try container.encode(str)
        case .int(let num): try container.encode(num)
        case .double(let num): try container.encode(num)
        case .bool(let bool): try container.encode(bool)
        case .null: try container.encodeNil()
        }
    }
}
