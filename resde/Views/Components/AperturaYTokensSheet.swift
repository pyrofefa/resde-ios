import SwiftUI

// MARK: - Sheet principal (tabs: Abrir Pluma / Generar Código)

struct AperturaYTokensSheet: View {
    @EnvironmentObject var authService: AuthService
    let ubicacionId: Int?
    let onAperturaResultado: (String) -> Void
    var soloGenerarCodigo: Bool = false
    var onTokenGenerado: (() -> Void)? = nil

    @Environment(\.dismiss) var dismiss
    @State private var tab: AperturaTab = .abrirPluma
    @State private var tokenGenerado: ClaveAccesoGenerada?
    @State private var errorApertura: ErrorPeticionMensaje?

    enum AperturaTab {
        case abrirPluma
        case generarCodigo
    }

    init(
        ubicacionId: Int?,
        onAperturaResultado: @escaping (String) -> Void,
        soloGenerarCodigo: Bool = false,
        onTokenGenerado: (() -> Void)? = nil
    ) {
        self.ubicacionId = ubicacionId
        self.onAperturaResultado = onAperturaResultado
        self.soloGenerarCodigo = soloGenerarCodigo
        self.onTokenGenerado = onTokenGenerado
        _tab = State(initialValue: soloGenerarCodigo ? .generarCodigo : .abrirPluma)
    }

    private var puedeAbrir: Bool { authService.puedeAbrirPluma }
    private var puedeGenerar: Bool { authService.puedeGenerarCodigo }

    /// Pestañas solo si el usuario tiene ambos permisos (como Android).
    private var mostrarPestanas: Bool { !soloGenerarCodigo && puedeAbrir && puedeGenerar }

    /// Contenido efectivo según permisos.
    private var tabEfectiva: AperturaTab {
        if soloGenerarCodigo { return .generarCodigo }
        if puedeAbrir && !puedeGenerar { return .abrirPluma }
        if !puedeAbrir && puedeGenerar { return .generarCodigo }
        return tab
    }

    private var mensajeSinPermiso: String? {
        if soloGenerarCodigo {
            return puedeGenerar ? nil : "No tienes permisos para generar códigos de acceso"
        }
        return (puedeAbrir || puedeGenerar) ? nil : "No tienes permisos para realizar estas acciones"
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            if mostrarPestanas {
                HStack(spacing: 0) {
                    AperturaTabButton(title: "Abrir Pluma", isSelected: tab == .abrirPluma) {
                        tab = .abrirPluma
                    }
                    AperturaTabButton(title: "Generar Código", isSelected: tab == .generarCodigo) {
                        tab = .generarCodigo
                    }
                }

                Divider()
            }

            if mensajeSinPermiso != nil {
                Color.clear.frame(height: 1)
            } else if tabEfectiva == .abrirPluma {
                AbrirPlumaTabView(
                    ubicacionId: ubicacionId,
                    authService: authService,
                    onResultado: { exito, mensaje in
                        if exito {
                            onAperturaResultado(mensaje)
                            dismiss()
                        } else {
                            errorApertura = ErrorPeticionMensaje(mensaje: mensaje)
                        }
                    }
                )
            } else {
                GenerarCodigoTabView(
                    ubicacionId: ubicacionId,
                    authService: authService,
                    onTokenGenerado: { token in
                        tokenGenerado = token
                        // Refrescar el listado de una vez, en cuanto se crea el token, en
                        // vez de esperar a que cierren la sheet — así ya terminó cuando
                        // el usuario le da a "Cerrar" y no hay carrera con el dismiss.
                        onTokenGenerado?()
                    }
                )
            }

            Spacer(minLength: 0)
        }
        .background(Color.appBackground)
        .onAppear {
            if let mensaje = mensajeSinPermiso {
                onAperturaResultado(mensaje)
                dismiss()
            }
        }
        .sheet(item: $tokenGenerado) { token in
            TokenGeneradoSheet(token: token, residencialFallback: authService.user?.residencial, onCerrar: {
                // Solo cerramos la sheet de afuera: al hacerlo, SwiftUI cierra junto
                // con ella la de "código generado" en una sola animación, sin que se
                // alcance a ver de regreso el formulario de "Generar Código".
                dismiss()
            })
            .presentationDetents([.fraction(0.6)])
        }
        .sheet(item: $errorApertura) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: { errorApertura = nil })
                .presentationDetents([.fraction(0.45)])
        }
    }
}

private struct AperturaTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .secondary)
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab: Abrir Pluma

private enum EstadoAperturaBoton {
    case normal
    case cargando
    case exito
}

private struct AbrirPlumaTabView: View {
    let ubicacionId: Int?
    let authService: AuthService
    let onResultado: (Bool, String) -> Void

    @State private var estado: EstadoAperturaBoton = .normal
    @State private var isPressing = false
    @State private var pulsoToque = false
    @State private var pulsoContinuo = false
    @State private var rebote = false
    @State private var aviso: String?

    private var colorBoton: Color {
        estado == .exito ? Color.statusSuccess : Color(red: 0.0, green: 0.4, blue: 0.7)
    }

    private var etiquetaBoton: String {
        switch estado {
        case .normal: return "ABRIR"
        case .cargando: return "ABRIENDO"
        case .exito: return "¡ABIERTO!"
        }
    }

    private var escala: CGFloat {
        if estado == .cargando { return pulsoContinuo ? 1.1 : 1.0 }
        if rebote { return 1.15 }
        return (isPressing || pulsoToque) ? 1.08 : 1.0
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Control de Acceso")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.blue)

            Text("Mantén presionado el círculo para abrir la pluma")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ZStack {
                Circle()
                    .fill(colorBoton)
                    .frame(width: 180, height: 180)
                    .scaleEffect(escala)
                    .animation(.easeOut(duration: 0.2), value: isPressing)
                    .animation(.easeOut(duration: 0.2), value: pulsoToque)
                    .animation(.easeOut(duration: 0.2), value: rebote)

                VStack(spacing: 8) {
                    if estado == .cargando {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: estado == .exito ? "checkmark" : "key.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    Text(etiquetaBoton)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .opacity(estado == .cargando ? 0.7 : 1.0)
            .allowsHitTesting(estado == .normal)
            .onTapGesture { mostrarAyudaToque() }
            .onLongPressGesture(
                minimumDuration: 0.8,
                pressing: { pressing in
                    guard estado == .normal else { return }
                    isPressing = pressing
                },
                perform: {
                    guard estado == .normal else { return }
                    isPressing = false
                    Task { await solicitarApertura() }
                }
            )

            Text(aviso ?? " ")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.8))
                .cornerRadius(8)
                .opacity(aviso == nil ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: aviso)
        }
        .padding(.vertical, 32)
    }

    // MARK: - Interacciones

    /// Toque simple: aviso y pulso breve (escala 1.08).
    private func mostrarAyudaToque() {
        guard estado == .normal else { return }
        aviso = "Mantén presionado el círculo unos segundos para abrir"
        pulsoToque = true
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            pulsoToque = false
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            aviso = nil
        }
    }

    private func iniciarPulsoContinuo() {
        pulsoContinuo = false
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulsoContinuo = true
        }
    }

    private func detenerPulsoContinuo() {
        withAnimation(.easeOut(duration: 0.15)) {
            pulsoContinuo = false
        }
    }

    private func animarRebote() {
        rebote = true
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            rebote = false
        }
    }

    // MARK: - Apertura

    private func solicitarApertura() async {
        guard let ubicacionId = ubicacionId else {
            onResultado(false, "Selecciona una ubicación válida")
            return
        }

        guard await Conectividad.hayInternet() else {
            onResultado(false, "No cuentas con conexión a internet en este momento.")
            return
        }

        aviso = nil
        estado = .cargando
        iniciarPulsoContinuo()

        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/pluma/abrir") else {
            detenerPulsoContinuo()
            estado = .normal
            onResultado(false, "URL inválida")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "ubicacion_id": ubicacionId,
            "dispositivo": PushNotificationManager.modeloDispositivo(),
            "ip": Conectividad.direccionIPLocal()
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)

            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response, data: data)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let decodificada = try? JSONDecoder().decode(AperturaPlumaResponse.self, from: data)
            let mensaje = decodificada?.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // Éxito: HTTP 2xx y, si el servidor manda `status`, que sea "success" u "ok" (como Android).
            let estadoServidor = decodificada?.status?.lowercased()
            let exitoso = (200..<300).contains(statusCode)
                && (estadoServidor == nil || estadoServidor == "success" || estadoServidor == "ok")

            detenerPulsoContinuo()

            if exitoso {
                estado = .exito
                animarRebote()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                onResultado(true, mensaje.isEmpty ? "¡Pluma abierta exitosamente!" : mensaje)
            } else {
                estado = .normal
                onResultado(false, mensaje.isEmpty ? "No fue posible abrir la pluma. Inténtalo de nuevo." : mensaje)
            }
        } catch {
            print("❌ Error al solicitar apertura de pluma: \(error)")
            detenerPulsoContinuo()
            estado = .normal
            onResultado(false, "Error de conexión o servidor al intentar abrir la pluma.")
        }
    }
}

// MARK: - Tab: Generar Código

private struct GenerarCodigoTabView: View {
    let ubicacionId: Int?
    let authService: AuthService
    let onTokenGenerado: (ClaveAccesoGenerada) -> Void

    @State private var nombre = ""
    @State private var tipoAcceso: TipoAccesoOpcion = .visita
    @State private var vigenciaHoras = 24
    @State private var limiteUsos = 1
    @State private var fechaEvento = Date()
    @State private var descripcion = ""
    @State private var isSubmitting = false
    @State private var errorPeticion: ErrorPeticionMensaje?

    private let opcionesVigencia = [3, 6, 12, 24]
    private let opcionesLimite = [1, 2, 0]
    private let diasMaximosEvento = 15
    private let maxCaracteresDescripcion = 100

    private var fechaMaximaEvento: Date {
        Calendar.current.date(byAdding: .day, value: diasMaximosEvento, to: Date()) ?? Date()
    }

    private var etiquetaFechaEvento: String {
        if Calendar.current.isDateInToday(fechaEvento) {
            return "Hoy"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: fechaEvento)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Generar Código de Acceso")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)

                Text("Crea un token temporal para visitas, paquetería o eventos.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                TextField("Nombre del visitante / Motivo", text: $nombre)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.fieldBackground)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))

                GrupoChips(titulo: "Tipo de acceso") {
                    ForEach(TipoAccesoOpcion.allCases) { opcion in
                        ChipOpcion(texto: opcion.label, seleccionado: tipoAcceso == opcion) {
                            tipoAcceso = opcion
                        }
                    }
                }

                switch tipoAcceso {
                case .paqueteria:
                    HStack(alignment: .top, spacing: 8) {
                        Text("📦")
                        Text("Paquetería: Configurado automáticamente con 1 solo uso y vigencia de 12 horas.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)

                case .reunion:
                    ZStack {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Fecha del evento: \(etiquetaFechaEvento)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.fieldBackground)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .allowsHitTesting(false)

                        DatePicker(
                            "",
                            selection: $fechaEvento,
                            in: Date()...fechaMaximaEvento,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .opacity(0.02)
                    }
                    .frame(height: 44)

                    HStack(alignment: .top, spacing: 8) {
                        Text("🎉")
                        Text("Reunión / Evento: Usos ilimitados durante el día seleccionado (hasta \(diasMaximosEvento) días a futuro).")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)

                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("Descripción del evento (opcional)", text: $descripcion, axis: .vertical)
                            .lineLimit(3...5)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(Color.fieldBackground)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            .onChange(of: descripcion) { _, nuevo in
                                if nuevo.count > maxCaracteresDescripcion {
                                    descripcion = String(nuevo.prefix(maxCaracteresDescripcion))
                                }
                            }

                        Text("\(descripcion.count)/\(maxCaracteresDescripcion)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                case .visita:
                    GrupoChips(titulo: "Vigencia") {
                        ForEach(opcionesVigencia, id: \.self) { horas in
                            ChipOpcion(texto: etiquetaVigencia(horas), seleccionado: vigenciaHoras == horas) {
                                vigenciaHoras = horas
                            }
                        }
                    }

                    GrupoChips(titulo: "Límite de usos") {
                        ForEach(opcionesLimite, id: \.self) { limite in
                            ChipOpcion(texto: etiquetaLimite(limite), seleccionado: limiteUsos == limite) {
                                limiteUsos = limite
                            }
                        }
                    }
                }

                Button(action: { Task { await generarToken() } }) {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSubmitting ? "Generando..." : "Generar Token de Acceso")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                    .cornerRadius(25)
                }
                .disabled(isSubmitting)
            }
            .padding(20)
        }
        .sheet(item: $errorPeticion) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: { errorPeticion = nil })
                .presentationDetents([.fraction(0.45)])
        }
    }

    private func etiquetaVigencia(_ horas: Int) -> String {
        "\(horas) horas"
    }

    private func etiquetaLimite(_ limite: Int) -> String {
        limite == 0 ? "Ilimitados" : "\(limite) uso\(limite == 1 ? "" : "s")"
    }

    private func generarToken() async {
        guard !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorPeticion = ErrorPeticionMensaje(mensaje: "El nombre del visitante o motivo es obligatorio")
            return
        }

        guard let ubicacionId = ubicacionId else {
            errorPeticion = ErrorPeticionMensaje(mensaje: "No se pudo determinar la ubicación")
            return
        }

        isSubmitting = true

        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/claves-acceso") else {
            isSubmitting = false
            errorPeticion = ErrorPeticionMensaje(mensaje: "URL inválida")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var params: [String: Any] = [
            "nombre": nombre,
            "ubicacion_id": ubicacionId,
            "tipo_acceso": tipoAcceso.rawValue
        ]

        switch tipoAcceso {
        case .reunion:
            let finDelDiaEvento = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: fechaEvento) ?? fechaEvento
            let diffHoras = Int(finDelDiaEvento.timeIntervalSince(Date()) / 3600)
            let duracionHoras = max(diffHoras, 24)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            params["limite_usos"] = 20
            params["duracion_horas"] = duracionHoras
            params["fecha_expiracion"] = dateFormatter.string(from: fechaEvento)

            // La descripción es opcional y solo aplica a reuniones (como Android).
            let descripcionLimpia = descripcion.trimmingCharacters(in: .whitespacesAndNewlines)
            if !descripcionLimpia.isEmpty {
                params["descripcion"] = descripcionLimpia
            }

        case .paqueteria:
            // Sin fecha_expiracion: el servidor la calcula con duracion_horas (igual que Android).
            params["limite_usos"] = 1
            params["duracion_horas"] = 12

        case .visita:
            // Sin fecha_expiracion: el servidor la calcula con duracion_horas (igual que Android).
            params["limite_usos"] = limiteUsos
            params["duracion_horas"] = vigenciaHoras
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)

            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response, data: data)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if statusCode == 200 || statusCode == 201 {
                if let claveResponse = try? JSONDecoder().decode(ClaveAccesoResponse.self, from: data),
                   let clave = claveResponse.clave {
                    isSubmitting = false
                    onTokenGenerado(clave)
                } else {
                    isSubmitting = false
                    errorPeticion = ErrorPeticionMensaje(mensaje: "No se pudo leer la respuesta del servidor")
                }
            } else {
                let mensaje = (try? JSONDecoder().decode(ClaveAccesoErrorResponse.self, from: data))?.message
                    ?? "No se pudo generar el código de acceso"
                isSubmitting = false
                errorPeticion = ErrorPeticionMensaje(mensaje: mensaje)
            }
        } catch {
            print("❌ Error al generar clave de acceso: \(error)")
            isSubmitting = false
            errorPeticion = ErrorPeticionMensaje(mensaje: "No se pudo generar el código de acceso")
        }
    }
}

enum TipoAccesoOpcion: String, CaseIterable, Identifiable {
    case visita = "visita"
    case paqueteria = "paqueteria"
    case reunion = "reunion"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .visita: return "Visita"
        case .paqueteria: return "Paquetería"
        case .reunion: return "Reunión / Evento"
        }
    }
}

// MARK: - Chips

private struct GrupoChips<Content: View>: View {
    let titulo: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titulo.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)

            ChipsFlowLayout(spacing: 10) {
                content()
            }
        }
    }
}

private struct ChipOpcion: View {
    let texto: String
    let seleccionado: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if seleccionado {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(texto)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(seleccionado ? Color.blue.opacity(0.18) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(seleccionado ? Color.clear : Color.gray.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Distribuye los chips en filas y salta de línea cuando no caben.
private struct ChipsFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, usedWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: usedWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct ErrorPeticionMensaje: Identifiable {
    let mensaje: String
    var id: String { mensaje }
}

struct ErrorPeticionDialog: View {
    let mensaje: String
    let onCerrar: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Spacer(minLength: 0)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("¡Atención!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)

            Text(mensaje)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: onCerrar) {
                Text("Entendido")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.selectedTint)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .background(Color.appBackground)
    }
}

// MARK: - Token generado

struct ClaveAccesoGenerada: Decodable, Identifiable {
    var id: String { token ?? UUID().uuidString }
    let token: String?
    let nombre: String?
    let descripcion: String?
    let ubicacion_nombre: String?
    let residencial: String?
    let tipo_acceso: String?
    let limite_usos: Int?
    let usos_restantes: Int?
    let fecha_expiracion: String?
    let fecha_expiracion_formato: String?
    let instrucciones_bot: String?
}

struct ClaveAccesoResponse: Decodable {
    let success: Bool?
    let clave: ClaveAccesoGenerada?
    let message: String?
}

struct ClaveAccesoErrorResponse: Decodable {
    let success: Bool?
    let message: String?
}

struct TokenGeneradoSheet: View {
    let token: ClaveAccesoGenerada
    var residencialFallback: String? = nil
    let onCerrar: () -> Void

    @State private var copiado = false

    private let botNumero = "14807419374"

    /// Enlace del botón del chat: "Hola, mi código de acceso es {token}" (como Android).
    private var whatsappLink: String {
        let mensaje = "Hola, mi código de acceso es \(token.token ?? "")"
        let encoded = mensaje.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mensaje
        return "https://wa.me/\(botNumero)?text=\(encoded)"
    }

    private var descripcionLimpia: String? {
        let texto = token.descripcion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return texto.isEmpty ? nil : texto
    }

    private var etiquetaNombre: String {
        let nombre = token.nombre ?? ""
        if let descripcion = descripcionLimpia {
            return "Evento/Reunión: \(nombre)\n💬 \(descripcion)"
        }
        return "Visitante: \(nombre)"
    }

    private var etiquetaVigencia: String {
        var texto = ""
        if let ubicacion = token.ubicacion_nombre, !ubicacion.isEmpty {
            texto += "Ubicación: \(ubicacion)\n"
        }
        texto += "Válido hasta: \(fechaFormateada)"
        return texto
    }

    private var mensajeCompartir: String {
        let residencial = token.residencial ?? residencialFallback ?? "Residencial"
        let codigo = token.token ?? ""
        let vigencia = token.fecha_expiracion_formato ?? "24 horas"
        let nombre = token.nombre ?? ""
        let enlace = "https://wa.me/\(botNumero)?text=\(codigo)"
        let cierre = "🔑 Código: \(codigo)\n🕒 Válido hasta: \(vigencia)\n\n💬 Toca el siguiente enlace para enviar tu código al asistente RESDE Guard y abrir automáticamente:\n\(enlace)"

        if let descripcion = descripcionLimpia {
            return "¡Hola! Te comparto la invitación para \(nombre) en \(residencial):\n\n💬 \"\(descripcion)\"\n\n\(cierre)"
        }
        return "¡Hola \(nombre)! Te comparto tu código de acceso para entrar a \(residencial):\n\n\(cierre)"
    }

    private var fechaFormateada: String {
        token.fecha_expiracion_formato ?? "24 horas"
    }

    private var numeroFormateado: String {
        "+1 (480) 741-9374"
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Código de Acceso Generado")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue)
                Text(token.instrucciones_bot ?? "Comparte esta información con tu visita.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)

            VStack(spacing: 10) {
                Text("CÓDIGO ÚNICO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.blue)
                    .tracking(1)

                Text(token.token ?? "-")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)

                if token.nombre != nil {
                    Text(etiquetaNombre)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Text(etiquetaVigencia)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Divider()
                    .padding(.vertical, 4)

                Text("ASISTENTE RESDE GUARD (WHATSAPP)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .tracking(0.5)

                Button(action: {
                    if let url = URL(string: whatsappLink) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(Color.whatsappGreen)
                        Text("\(numeroFormateado) (Tocar para chatear)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.whatsappGreen)
                    }
                    .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.fieldBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.4), lineWidth: 1))

            HStack(spacing: 12) {
                Button(action: {
                    UIPasteboard.general.string = token.token ?? ""
                    copiado = true
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        copiado = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: copiado ? "checkmark" : "doc.on.doc")
                        Text(copiado ? "Copiado" : "Copiar")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.selectedTint)
                    .cornerRadius(10)
                }

                ShareLink(item: mensajeCompartir) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartir")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                    .cornerRadius(10)
                }
            }

            Button(action: onCerrar) {
                Text("Cerrar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(12)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color.appBackground)
    }
}
