import SwiftUI

struct ClavesAccesoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var claves: [ClaveAccesoActiva] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showGenerarCodigo = false
    @State private var copiadoToken: String?
    @State private var claveADesactivar: ClaveAccesoActiva?
    @State private var isDesactivando = false

    private let botNumero = "14807419374"

    private var ubicacionId: Int? {
        Int(authService.user?.ubicaciones.first?.key ?? "")
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Claves de acceso")
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

                        HStack(spacing: 8) {
                            Text("CLAVES ACTIVAS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Text("\(claves.count)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.gray.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 16)

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
                        } else if claves.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No hay claves de acceso activas")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Toca el botón + para generar una nueva clave")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 80)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(claves) { clave in
                                    ClaveAccesoCard(
                                        clave: clave,
                                        botNumero: botNumero,
                                        copiado: copiadoToken == clave.token,
                                        onCopiar: {
                                            UIPasteboard.general.string = clave.token ?? ""
                                            copiadoToken = clave.token
                                            Task {
                                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                                if copiadoToken == clave.token {
                                                    copiadoToken = nil
                                                }
                                            }
                                        },
                                        onDesactivar: {
                                            claveADesactivar = clave
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(Color.appBackground)
            .navigationBarBackButtonHidden()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showGenerarCodigo = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Nueva Clave")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                        .cornerRadius(28)
                    }
                    .padding(16)
                }
            }

            if let clave = claveADesactivar {
                DesactivarClaveOverlay(
                    clave: clave,
                    isLoading: isDesactivando,
                    onCancel: { claveADesactivar = nil },
                    onConfirm: {
                        Task { await desactivarClave(clave) }
                    }
                )
            }
        }
        .sheet(isPresented: $showGenerarCodigo) {
            AperturaYTokensSheet(
                ubicacionId: ubicacionId,
                onAperturaResultado: { _ in },
                soloGenerarCodigo: true,
                onTokenGenerado: {
                    Task { await loadClaves() }
                }
            )
            .environmentObject(authService)
            .presentationDetents([.fraction(0.6), .large])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            Task { await loadClaves() }
        }
    }

    private func loadClaves() async {
        isLoading = true
        showError = false

        guard let url = buildURL() else {
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
                errorMessage = "No se pudieron cargar las claves de acceso"
                showError = true
                return
            }

            let decoded = try JSONDecoder().decode(ClavesAccesoActivasResponse.self, from: data)
            claves = decoded.claves ?? []
            isLoading = false
        } catch {
            print("❌ Error al cargar claves de acceso: \(error)")
            isLoading = false
            errorMessage = "No se pudieron cargar las claves de acceso"
            showError = true
        }
    }

    private func buildURL() -> URL? {
        var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/claves-acceso/activas")
        if let ubicacionId = ubicacionId {
            components?.queryItems = [URLQueryItem(name: "ubicacion_id", value: String(ubicacionId))]
        }
        return components?.url
    }

    private func desactivarClave(_ clave: ClaveAccesoActiva) async {
        guard let claveId = clave.claveId,
              let url = URL(string: "https://resde.aseenti.com.mx/api/v1/claves-acceso/\(claveId)/desactivar") else {
            claveADesactivar = nil
            return
        }

        isDesactivando = true

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            isDesactivando = false
            claveADesactivar = nil

            if statusCode >= 200 && statusCode < 300 {
                claves.removeAll { $0.id == clave.id }
            }
        } catch {
            print("❌ Error al desactivar clave: \(error)")
            isDesactivando = false
            claveADesactivar = nil
        }
    }
}

// MARK: - Confirmación de desactivación

private struct DesactivarClaveOverlay: View {
    let clave: ClaveAccesoActiva
    let isLoading: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { if !isLoading { onCancel() } }

            VStack(alignment: .leading, spacing: 16) {
                Text("Desactivar clave")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text("¿Seguro que quieres desactivar el código \(clave.token ?? "")? Ya no podrá usarse para dar acceso.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Button(action: onCancel) {
                        Text("Cancelar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .disabled(isLoading)
                    .padding(.trailing, 16)

                    Button(action: onConfirm) {
                        Text("Desactivar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .frame(maxWidth: 320)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Card

private struct ClaveAccesoCard: View {
    let clave: ClaveAccesoActiva
    let botNumero: String
    let copiado: Bool
    let onCopiar: () -> Void
    let onDesactivar: () -> Void

    private var esValida: Bool {
        clave.es_valida ?? true
    }

    private var whatsappLink: String {
        let mensaje = clave.token ?? ""
        let encoded = mensaje.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mensaje
        return "https://wa.me/\(botNumero)?text=\(encoded)"
    }

    private var mensajeCompartir: String {
        "Tu código de acceso es: \(clave.token ?? ""). Envíalo a nuestro asistente RESDE Guard: \(whatsappLink)"
    }

    private var fechaFormateada: String {
        clave.fecha_expiracion_formato ?? clave.fecha_expiracion ?? "-"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(clave.nombre ?? "Sin motivo especificado")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.blue)
                Spacer()
                Text(esValida ? "Válida" : "Expirada / Agotada")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(esValida ? Color(red: 0.2, green: 0.7, blue: 0.2) : Color(red: 0.8, green: 0.2, blue: 0.2))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(esValida ? Color(red: 0.2, green: 0.7, blue: 0.2) : Color(red: 0.8, green: 0.2, blue: 0.2), lineWidth: 1))
            }

            Text("TIPO: \(tipoAccesoLabel(clave.tipo_acceso).uppercased())")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blue)

            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CÓDIGO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1)
                    Text(clave.token ?? "-")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.fieldBackground)
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                if let limite = clave.limite_usos {
                    Text("Usos restantes: \(clave.usos_restantes ?? 0) (Límite: \(limite))")
                } else {
                    Text("Usos ilimitados")
                }
                Text("Válido hasta: \(fechaFormateada)")
            }
            .font(.system(size: 13))
            .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button(action: onCopiar) {
                    HStack(spacing: 6) {
                        Image(systemName: copiado ? "checkmark" : "doc.on.doc")
                        Text(copiado ? "Copiado" : "Copiar")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.selectedTint)
                    .cornerRadius(8)
                }

                ShareLink(item: mensajeCompartir) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartir")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                    .cornerRadius(8)
                }
            }

            if esValida {
                Button(action: onDesactivar) {
                    Text("Desactivar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    private func tipoAccesoLabel(_ raw: String?) -> String {
        switch raw?.lowercased() {
        case "visita": return "Visita"
        case "paqueteria": return "Paquetería"
        case "evento", "reunion": return "Reunión/Evento"
        default: return raw?.capitalized ?? "Acceso"
        }
    }
}

// MARK: - Modelos

struct ClaveAccesoActiva: Decodable, Identifiable {
    var id: String { claveId.map(String.init) ?? token ?? UUID().uuidString }
    let claveId: Int?
    let token: String?
    let nombre: String?
    let ubicacion_id: Int?
    let ubicacion_nombre: String?
    let tipo_acceso: String?
    let limite_usos: Int?
    let usos_registrados: Int?
    let usos_restantes: Int?
    let fecha_expiracion: String?
    let fecha_expiracion_formato: String?
    let status: Int?
    let es_valida: Bool?
    let created: String?

    private enum CodingKeys: String, CodingKey {
        case claveId = "id"
        case token, nombre, ubicacion_id, ubicacion_nombre, tipo_acceso
        case limite_usos, usos_registrados, usos_restantes
        case fecha_expiracion, fecha_expiracion_formato
        case status, es_valida, created
    }
}

struct ClavesAccesoActivasResponse: Decodable {
    let success: Bool?
    let total: Int?
    let claves: [ClaveAccesoActiva]?
    let message: String?
}

#Preview {
    ClavesAccesoView()
        .environmentObject(AuthService(mockData: true))
}
