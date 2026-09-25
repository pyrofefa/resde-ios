import SwiftUI

struct HistorialAccesosView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var entradas: [HistorialEntrada] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentPage = 1
    @State private var lastPage = 1
    @State private var showFiltros = false
    @State private var estadoFiltro: EstadoFiltro = .todos
    @State private var fechaInicioFiltro: Date?
    @State private var fechaFinFiltro: Date?

    private var hayFiltrosActivos: Bool {
        estadoFiltro != .todos || fechaInicioFiltro != nil || fechaFinFiltro != nil
    }

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
                Button(action: { showFiltros = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(hayFiltrosActivos ? ".fill" : "")")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
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

                    if hayFiltrosActivos {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .foregroundColor(.blue)
                            Text(resumenFiltros)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.blue)
                            Spacer()
                            Button(action: {
                                limpiarFiltros()
                                Task { await loadHistorial(page: 1) }
                            }) {
                                Text("Limpiar")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    }

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

                            if currentPage < lastPage {
                                Button(action: { Task { await loadHistorial(page: currentPage + 1) } }) {
                                    HStack(spacing: 8) {
                                        if isLoadingMore {
                                            ProgressView()
                                        }
                                        Text(isLoadingMore ? "Cargando..." : "Cargar más")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                }
                                .disabled(isLoadingMore)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await loadHistorial(page: 1)
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            Task { await loadHistorial(page: 1) }
        }
        .sheet(isPresented: $showFiltros) {
            FiltrosHistorialSheet(
                estadoFiltro: estadoFiltro,
                fechaInicioFiltro: fechaInicioFiltro,
                fechaFinFiltro: fechaFinFiltro,
                onAplicar: { estado, desde, hasta in
                    estadoFiltro = estado
                    fechaInicioFiltro = desde
                    fechaFinFiltro = hasta
                    showFiltros = false
                    Task { await loadHistorial(page: 1) }
                },
                onLimpiar: {
                    limpiarFiltros()
                    showFiltros = false
                    Task { await loadHistorial(page: 1) }
                }
            )
            .presentationDetents([.fraction(0.55)])
        }
    }

    private var resumenFiltros: String {
        var partes: [String] = []
        if estadoFiltro != .todos {
            partes.append(estadoFiltro.label)
        }
        if let desde = fechaInicioFiltro, let hasta = fechaFinFiltro {
            partes.append("\(formatoCorto(desde)) - \(formatoCorto(hasta))")
        } else if let desde = fechaInicioFiltro {
            partes.append("Desde \(formatoCorto(desde))")
        } else if let hasta = fechaFinFiltro {
            partes.append("Hasta \(formatoCorto(hasta))")
        }
        return partes.joined(separator: " · ")
    }

    private func formatoCorto(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    private func limpiarFiltros() {
        estadoFiltro = .todos
        fechaInicioFiltro = nil
        fechaFinFiltro = nil
    }

    private func loadHistorial(page: Int) async {
        guard let ubicacionId = ubicacionId else {
            isLoading = false
            errorMessage = "No se pudo determinar la ubicación"
            showError = true
            return
        }

        if page == 1 {
            isLoading = true
        } else {
            isLoadingMore = true
        }
        showError = false

        var queryItems = [
            URLQueryItem(name: "ubicacion_id", value: String(ubicacionId)),
            URLQueryItem(name: "per_page", value: "20"),
            URLQueryItem(name: "page", value: String(page))
        ]

        if estadoFiltro != .todos {
            queryItems.append(URLQueryItem(name: "estado", value: estadoFiltro.rawValue))
        }

        let fechaParamFormatter = DateFormatter()
        fechaParamFormatter.dateFormat = "yyyy-MM-dd"

        if let desde = fechaInicioFiltro {
            queryItems.append(URLQueryItem(name: "fecha_inicio", value: fechaParamFormatter.string(from: desde)))
        }
        if let hasta = fechaFinFiltro {
            queryItems.append(URLQueryItem(name: "fecha_fin", value: fechaParamFormatter.string(from: hasta)))
        }

        var components = URLComponents(string: "https://resde.aseenti.com.mx/api/v1/pluma/entradas")
        components?.queryItems = queryItems

        guard let url = components?.url else {
            isLoading = false
            isLoadingMore = false
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
                isLoadingMore = false
                errorMessage = "No se pudo cargar el historial de accesos"
                showError = true
                return
            }

            let decoded = try JSONDecoder().decode(HistorialAccesosResponse.self, from: data)
            if page == 1 {
                entradas = decoded.data ?? []
            } else {
                entradas.append(contentsOf: decoded.data ?? [])
            }
            currentPage = decoded.current_page ?? page
            lastPage = decoded.last_page ?? page
            isLoading = false
            isLoadingMore = false
        } catch {
            print("❌ Error al cargar historial de accesos: \(error)")
            isLoading = false
            isLoadingMore = false
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
            return Color.statusSuccess
        case let e where e.contains("inicia") || e.contains("pending"):
            return Color.statusWarning
        case let e where e.contains("fall") || e.contains("error"):
            return Color.statusError
        default:
            return .secondary
        }
    }

    private var fechaFormateada: String {
        guard let fecha = entrada.fecha else { return "-" }
        let parser = DateFormatter()
        parser.dateFormat = "dd/MM/yyyy HH:mm:ss"
        guard let date = parser.date(from: fecha) else { return fecha }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entrada.usuario ?? "Desconocido")
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

            if let dispositivo = entrada.dispositivo {
                HStack(spacing: 4) {
                    Image(systemName: "iphone")
                    Text(dispositivo)
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
                            .foregroundColor(Color.whatsappGreen)
                        if let nombreClave = entrada.nombre_clave {
                            Text("\(nombreClave)\(entrada.tipo_clave.map { " · \($0.capitalized)" } ?? "")")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.whatsappGreen.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Filtros

enum EstadoFiltro: String, CaseIterable {
    case todos = ""
    case exito = "exito"
    case iniciada = "iniciada"
    case fallido = "fallido"

    var label: String {
        switch self {
        case .todos: return "Todos"
        case .exito: return "Éxito"
        case .iniciada: return "Iniciada"
        case .fallido: return "Fallido"
        }
    }
}

private struct FiltrosHistorialSheet: View {
    let estadoFiltro: EstadoFiltro
    let fechaInicioFiltro: Date?
    let fechaFinFiltro: Date?
    let onAplicar: (EstadoFiltro, Date?, Date?) -> Void
    let onLimpiar: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var estado: EstadoFiltro
    @State private var incluirDesde: Bool
    @State private var desde: Date
    @State private var incluirHasta: Bool
    @State private var hasta: Date

    init(estadoFiltro: EstadoFiltro, fechaInicioFiltro: Date?, fechaFinFiltro: Date?, onAplicar: @escaping (EstadoFiltro, Date?, Date?) -> Void, onLimpiar: @escaping () -> Void) {
        self.estadoFiltro = estadoFiltro
        self.fechaInicioFiltro = fechaInicioFiltro
        self.fechaFinFiltro = fechaFinFiltro
        self.onAplicar = onAplicar
        self.onLimpiar = onLimpiar
        _estado = State(initialValue: estadoFiltro)
        _incluirDesde = State(initialValue: fechaInicioFiltro != nil)
        _desde = State(initialValue: fechaInicioFiltro ?? Date())
        _incluirHasta = State(initialValue: fechaFinFiltro != nil)
        _hasta = State(initialValue: fechaFinFiltro ?? Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Filtrar historial")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estado")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(EstadoFiltro.allCases, id: \.self) { opcion in
                                Button(action: { estado = opcion }) {
                                    Text(opcion.label)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(estado == opcion ? .white : .primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(estado == opcion ? Color.blue : Color.fieldBackground)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Desde", isOn: $incluirDesde)
                            .font(.system(size: 14, weight: .semibold))
                        if incluirDesde {
                            DatePicker("", selection: $desde, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Hasta", isOn: $incluirHasta)
                            .font(.system(size: 14, weight: .semibold))
                        if incluirHasta {
                            DatePicker("", selection: $hasta, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }

                    Button(action: {
                        onAplicar(estado, incluirDesde ? desde : nil, incluirHasta ? hasta : nil)
                    }) {
                        Text("Aplicar filtros")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                            .cornerRadius(25)
                    }

                    Button(action: onLimpiar) {
                        Text("Limpiar filtros")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.appBackground)
    }
}

// MARK: - Modelos

struct HistorialEntrada: Decodable, Identifiable {
    let id = UUID()
    let usuario: String?
    let ubicacion: String?
    let fecha: String?
    let dispositivo: String?
    let estado: String?
    let es_bot: Bool?
    let nombre_clave: String?
    let tipo_clave: String?

    private enum CodingKeys: String, CodingKey {
        case usuario, ubicacion, fecha, dispositivo, estado, es_bot, nombre_clave, tipo_clave
    }
}

struct HistorialAccesosResponse: Decodable {
    let success: Bool?
    let total: Int?
    let current_page: Int?
    let last_page: Int?
    let per_page: Int?
    let data: [HistorialEntrada]?
    let message: String?
}

#Preview {
    HistorialAccesosView()
        .environmentObject(AuthService(mockData: true))
}
