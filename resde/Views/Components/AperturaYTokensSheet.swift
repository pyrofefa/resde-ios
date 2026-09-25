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

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)

            if !soloGenerarCodigo {
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

            if tab == .abrirPluma {
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
                    }
                )
            }

            Spacer(minLength: 0)
        }
        .background(Color.appBackground)
        .sheet(item: $tokenGenerado) { token in
            TokenGeneradoSheet(token: token, onCerrar: {
                tokenGenerado = nil
                onTokenGenerado?()
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
                    .scaleEffect(isPressing ? 1.08 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: isPressing)

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
        }
        .padding(.vertical, 32)
    }

    private func solicitarApertura() async {
        guard let ubicacionId = ubicacionId else {
            onResultado(false, "No se pudo determinar la ubicación")
            return
        }

        estado = .cargando

        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/pluma/abrir") else {
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
            "dispositivo": UIDevice.current.name
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)

            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if statusCode >= 200 && statusCode < 300 {
                let mensaje = (try? JSONDecoder().decode(AperturaPlumaResponse.self, from: data))?.message
                    ?? "Solicitud de apertura iniciada"
                estado = .exito
                try? await Task.sleep(nanoseconds: 900_000_000)
                onResultado(true, mensaje)
            } else {
                let mensaje = (try? JSONDecoder().decode(AperturaPlumaResponse.self, from: data))?.message
                    ?? "No se pudo iniciar la apertura"
                estado = .normal
                onResultado(false, mensaje)
            }
        } catch {
            print("❌ Error al solicitar apertura de pluma: \(error)")
            estado = .normal
            onResultado(false, "No se pudo iniciar la apertura")
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
    @State private var isSubmitting = false
    @State private var errorPeticion: ErrorPeticionMensaje?

    private let opcionesVigencia = [3, 6, 12, 24]
    private let opcionesLimite = [1, 2, 0]
    private let diasMaximosEvento = 15

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

                CampoSelector(label: "Tipo de acceso", valor: tipoAcceso.label) {
                    ForEach(TipoAccesoOpcion.allCases) { opcion in
                        Button(opcion.label) { tipoAcceso = opcion }
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

                case .visita:
                    CampoSelector(label: "Vigencia", valor: etiquetaVigencia(vigenciaHoras)) {
                        ForEach(opcionesVigencia, id: \.self) { horas in
                            Button(etiquetaVigencia(horas)) { vigenciaHoras = horas }
                        }
                    }

                    CampoSelector(label: "Límite de usos", valor: etiquetaLimite(limiteUsos)) {
                        ForEach(opcionesLimite, id: \.self) { limite in
                            Button(etiquetaLimite(limite)) { limiteUsos = limite }
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
        if horas >= 24 && horas % 24 == 0 {
            let dias = horas / 24
            return "\(dias) día\(dias == 1 ? "" : "s")"
        }
        return "\(horas) hora\(horas == 1 ? "" : "s")"
    }

    private func etiquetaLimite(_ limite: Int) -> String {
        limite == 0 ? "Ilimitado" : "\(limite) uso\(limite == 1 ? "" : "s")"
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

        case .paqueteria:
            let horasPaqueteria = 12
            let fechaExpiracion = Calendar.current.date(byAdding: .hour, value: horasPaqueteria, to: Date()) ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            params["limite_usos"] = 1
            params["duracion_horas"] = horasPaqueteria
            params["fecha_expiracion"] = dateFormatter.string(from: fechaExpiracion)

        case .visita:
            let fechaExpiracion = Calendar.current.date(byAdding: .hour, value: vigenciaHoras, to: Date()) ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            params["limite_usos"] = limiteUsos
            params["duracion_horas"] = vigenciaHoras
            params["fecha_expiracion"] = dateFormatter.string(from: fechaExpiracion)
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)

            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
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
        case .reunion: return "Reunión/Evento"
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

private struct CampoSelector<MenuContent: View>: View {
    let label: String
    let valor: String
    @ViewBuilder let menuContent: () -> MenuContent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            Menu {
                menuContent()
            } label: {
                HStack {
                    Text(valor)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.fieldBackground)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
        }
    }
}

// MARK: - Token generado

struct ClaveAccesoGenerada: Decodable, Identifiable {
    var id: String { token ?? UUID().uuidString }
    let token: String?
    let nombre: String?
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
    let onCerrar: () -> Void

    @State private var copiado = false

    private let botNumero = "14807419374"

    private var whatsappLink: String {
        let mensaje = token.token ?? ""
        let encoded = mensaje.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? mensaje
        return "https://wa.me/\(botNumero)?text=\(encoded)"
    }

    private var mensajeCompartir: String {
        "Tu código de acceso es: \(token.token ?? ""). Envíalo a nuestro asistente RESDE Guard: \(whatsappLink)"
    }

    private var fechaFormateada: String {
        token.fecha_expiracion_formato ?? token.fecha_expiracion ?? "-"
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

                if let nombre = token.nombre {
                    Text("Visitante: \(nombre)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Text("Válido hasta: \(fechaFormateada)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

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
