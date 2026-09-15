import SwiftUI

struct HistorialAccesosView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var entradas: [HistorialEntrada] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""

    private var ubicacionId: Int? {
        Int(authService.user?.ubicaciones.first?.key ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Historial de accesos")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ubicación")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(authService.user?.ubicaciones.first?.value ?? "N/A")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else if showError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    } else if entradas.isEmpty {
                        Text("No hay accesos registrados")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(entradas) { entrada in
                                HistorialEntradaCard(entrada: entrada)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await loadHistorial()
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            Task { await loadHistorial() }
        }
    }

    private func loadHistorial() async {
        guard let ubicacionId = ubicacionId else {
            isLoading = false
            errorMessage = "No se pudo determinar la ubicación"
            showError = true
            return
        }

        isLoading = true
        showError = false

        var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/pluma/entradas")
        components?.queryItems = [
            URLQueryItem(name: "ubicacion_id", value: String(ubicacionId)),
            URLQueryItem(name: "per_page", value: "50")
        ]

        guard let url = components?.url else {
            isLoading = false
            errorMessage = "URL inválida"
            showError = true
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard statusCode == 200 else {
                isLoading = false
                errorMessage = "No se pudo cargar el historial de accesos"
                showError = true
                return
            }

            let decoded = try JSONDecoder().decode(HistorialAccesosResponse.self, from: data)
            entradas = decoded.data ?? []
            isLoading = false
        } catch {
            print("❌ Error al cargar historial de accesos: \(error)")
            isLoading = false
            errorMessage = "No se pudo cargar el historial de accesos"
            showError = true
        }
    }
}

// MARK: - Card

private struct HistorialEntradaCard: View {
    let entrada: HistorialEntrada

    private var colorEstado: Color {
        switch entrada.estado?.lowercased() ?? "" {
        case let e where e.contains("exit") || e.contains("success") || e.contains("éxit"):
            return Color(red: 0.2, green: 0.7, blue: 0.2)
        case let e where e.contains("inicia") || e.contains("pending"):
            return Color(red: 0.9, green: 0.6, blue: 0.0)
        case let e where e.contains("fall") || e.contains("error"):
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        default:
            return .secondary
        }
    }

    private var fechaFormateada: String {
        guard let fecha = entrada.fecha else { return "-" }
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = parser.date(from: fecha) else { return fecha }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entrada.nombre ?? "Desconocido")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text((entrada.estado ?? "-").capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colorEstado)
                    .cornerRadius(12)
            }

            Text(fechaFormateada)
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            if entrada.dispositivo != nil || entrada.ip_address != nil {
                HStack(spacing: 12) {
                    if let dispositivo = entrada.dispositivo {
                        HStack(spacing: 4) {
                            Image(systemName: "iphone")
                            Text(dispositivo)
                        }
                    }
                    if let ip = entrada.ip_address {
                        HStack(spacing: 4) {
                            Image(systemName: "network")
                            Text(ip)
                        }
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }

            if entrada.es_bot == true {
                HStack(spacing: 8) {
                    Text("🤖")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bot WhatsApp")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.15, green: 0.7, blue: 0.35))
                        if let nombreClave = entrada.nombre_clave {
                            Text("\(nombreClave)\(entrada.tipo_clave.map { " · \($0.capitalized)" } ?? "")")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color(red: 0.15, green: 0.7, blue: 0.35).opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Modelos

struct HistorialEntrada: Decodable, Identifiable {
    let id = UUID()
    let nombre: String?
    let fecha: String?
    let dispositivo: String?
    let ip_address: String?
    let estado: String?
    let es_bot: Bool?
    let nombre_clave: String?
    let tipo_clave: String?

    private enum CodingKeys: String, CodingKey {
        case nombre, fecha, dispositivo, ip_address, estado, es_bot, nombre_clave, tipo_clave
    }
}

struct HistorialAccesosResponse: Decodable {
    let success: Bool?
    let data: [HistorialEntrada]?
    let message: String?
}

#Preview {
    HistorialAccesosView()
        .environmentObject(AuthService(mockData: true))
}
