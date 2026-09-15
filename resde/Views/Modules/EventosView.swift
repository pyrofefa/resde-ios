//
//  EventosView.swift
//  resde
//

import SwiftUI

struct EventosView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var areasComunes: [AreaComun] = []
    @State private var selectedArea: AreaComun?
    @State private var diasApartados: [String] = []
    @State private var misReservas: [Reserva] = []
    @State private var selectedDate = Date()
    @State private var displayMonth = Date()
    @State private var isLoading = true
    @State private var showCreateEvento = false
    @State private var errorAlert: ErrorPeticionMensaje?
    @State private var selectedEvento: Reserva?

    var currentMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: displayMonth)) ?? Date()
    }

    var daysInMonth: [Int] {
        let range = Calendar.current.range(of: .day, in: .month, for: currentMonth)!
        return Array(1...range.count)
    }

    var firstWeekday: Int {
        let components = Calendar.current.dateComponents([.weekday], from: currentMonth)
        return (components.weekday ?? 1) - 1
    }

    var eventosDelDia: [Reserva] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let selectedDateString = formatter.string(from: selectedDate)
        return misReservas.filter { String($0.fecha_inicio?.prefix(10) ?? "") == selectedDateString }
    }

    var fechaSeleccionadaOcupada: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return diasApartados.contains(formatter.string(from: selectedDate))
    }

    var fechaMinima: Date {
        Date().addingTimeInterval(36 * 3600)
    }

    private func mostrarToast(_ mensaje: String) {
        errorAlert = ErrorPeticionMensaje(mensaje: mensaje)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Eventos")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(16)
                .background(Color(red: 0.05, green: 0.2, blue: 0.35))

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Área Común")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Menu {
                                ForEach(areasComunes, id: \.id) { area in
                                    Button(action: {
                                        selectedArea = area
                                        loadReservas()
                                    }) {
                                        Text(area.nombre ?? "")
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedArea?.nombre ?? "Seleccione un área")
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedArea == nil ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 2))
                            }
                        }
                        .padding(16)

                        VStack(spacing: 12) {
                            HStack {
                                Text(monthYearString)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: { changeMonth(by: -1) }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                Button(action: { changeMonth(by: 1) }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }

                            CalendarView(
                                selectedDate: $selectedDate,
                                displayMonth: $displayMonth,
                                diasApartados: diasApartados,
                                daysInMonth: daysInMonth,
                                firstWeekday: firstWeekday,
                                fechaMinimaReference: fechaMinima,
                                onInvalidDate: {
                                    mostrarToast("La reserva debe ser con mínimo 36 horas de anticipación")
                                }
                            )
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("EVENTOS PROGRAMADOS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else if eventosDelDia.isEmpty {
                                Text("No hay eventos para hoy")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(24)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(eventosDelDia, id: \.id) { evento in
                                        Button(action: { selectedEvento = evento }) {
                                            EventoCard(evento: evento)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .padding(16)
                }
            }
            .background(Color.appBackground)
            .navigationBarBackButtonHidden()

            VStack {
                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        if fechaSeleccionadaOcupada {
                            mostrarToast("La fecha seleccionada no está disponible para una nueva reserva")
                        } else {
                            showCreateEvento = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showCreateEvento) {
            if let area = selectedArea {
                CreateEventoSheet(
                    isPresented: $showCreateEvento,
                    area: area,
                    fechaPreseleccionada: selectedDate,
                    onEventoCreated: { loadReservas() }
                )
                .environmentObject(authService)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $selectedEvento) { evento in
            DetalleReservaSheet(evento: evento)
                .environmentObject(authService)
                .presentationDetents([.fraction(0.6), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $errorAlert) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: { errorAlert = nil })
                .presentationDetents([.fraction(0.45)])
        }
        .onAppear {
            displayMonth = Date()
            loadAreasComunes()
        }
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: currentMonth).capitalized
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            displayMonth = newDate
        }
    }

    private func loadAreasComunes() {
        Task {
            isLoading = true
            if let data = await fetchAreasComunes() {
                if let response = try? JSONDecoder().decode(AreasComunesResponse.self, from: data) {
                    await MainActor.run {
                        self.areasComunes = response.data ?? []
                        if let first = self.areasComunes.first {
                            self.selectedArea = first
                            self.loadReservas()
                        }
                    }
                }
            }
            isLoading = false
        }
    }

    private func loadReservas() {
        Task {
            isLoading = true
            if let areaId = selectedArea?.id, let data = await fetchReservas(areaId: areaId) {
                if let response = try? JSONDecoder().decode(ReservasResponse.self, from: data) {
                    await MainActor.run {
                        self.diasApartados = response.dias_apartados ?? []
                        self.misReservas = response.mis_reservas ?? []
                    }
                }
            }
            isLoading = false
        }
    }

    private func fetchAreasComunes() async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/eventos/areas-comunes") else {
            return nil
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            return data
        } catch {
            print("❌ Error fetching áreas: \(error)")
            return nil
        }
    }

    private func fetchReservas(areaId: Int) async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/eventos/reservas-activas?area_comun_id=\(areaId)") else {
            return nil
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            return data
        } catch {
            print("❌ Error fetching reservas: \(error)")
            return nil
        }
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var displayMonth: Date
    let diasApartados: [String]
    let daysInMonth: [Int]
    let firstWeekday: Int
    let fechaMinimaReference: Date
    let onInvalidDate: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(["D", "L", "M", "M", "J", "V", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 8) {
                ForEach(0..<((daysInMonth.count + firstWeekday + 6) / 7), id: \.self) { week in
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            let index = week * 7 + day - firstWeekday
                            if index >= 0 && index < daysInMonth.count {
                                CalendarDayCell(
                                    dayNum: daysInMonth[index],
                                    selectedDate: $selectedDate,
                                    displayMonth: $displayMonth,
                                    diasApartados: diasApartados,
                                    fechaMinimaReference: fechaMinimaReference,
                                    onInvalidDate: onInvalidDate
                                )
                            } else {
                                Text("")
                                .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CalendarDayCell: View {
    let dayNum: Int
    @Binding var selectedDate: Date
    @Binding var displayMonth: Date
    let diasApartados: [String]
    let fechaMinimaReference: Date
    let onInvalidDate: () -> Void

    var body: some View {
        let calendar = Calendar.current
        let components = DateComponents(
            year: calendar.component(.year, from: displayMonth),
            month: calendar.component(.month, from: displayMonth),
            day: dayNum
        )

        if let dayDate = calendar.date(from: components) {
            let dateStr = String(format: "%04d-%02d-%02d",
                calendar.component(.year, from: dayDate),
                calendar.component(.month, from: dayDate),
                dayNum
            )

            let isSelected = calendar.isDate(selectedDate, inSameDayAs: dayDate)
            let isOccupied = diasApartados.contains(dateStr)
            let isTooSoon = dayDate < fechaMinimaReference
            let isDisabled = isTooSoon || isOccupied

            return AnyView(
                Button(action: {
                    if isTooSoon {
                        onInvalidDate()
                    } else {
                        selectedDate = dayDate
                        displayMonth = dayDate
                    }
                }) {
                    DayCellContent(dayNum: dayNum, isSelected: isSelected, isOccupied: isOccupied, isTooSoon: isTooSoon)
                }
                .disabled(false)
            )
        } else {
            return AnyView(
                Text("")
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            )
        }
    }
}

struct DayCellContent: View {
    let dayNum: Int
    let isSelected: Bool
    let isOccupied: Bool
    let isTooSoon: Bool

    private var backgroundColor: Color {
        if isOccupied { return Color.red }
        if isSelected { return Color.blue }
        return Color.clear
    }

    private var textColor: Color {
        if isOccupied || isSelected { return .white }
        if isTooSoon { return .gray }
        return .primary
    }

    var body: some View {
        Text(String(dayNum))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected && !isOccupied ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
}

struct EventoCard: View {
    let evento: Reserva

    private var estatusTexto: String {
        evento.adeudo_evento?.estatus_pago?.descripcion ?? "Pendiente"
    }

    private var estatusColor: Color {
        switch estatusTexto.lowercased() {
        case "pagado":
            return Color(red: 0.2, green: 0.7, blue: 0.2)
        case "pendiente":
            return Color(red: 0.9, green: 0.6, blue: 0.1)
        default:
            return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(evento.titulo ?? "Evento")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    if let areaNombre = evento.area_comun_nombre {
                        Text(areaNombre)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                Text(estatusTexto.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(estatusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(estatusColor.opacity(0.15))
                    .cornerRadius(12)
            }
            Text("\(evento.hora_inicio ?? "")  - \(evento.hora_fin ?? "")")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct AreaComun: Codable, Identifiable {
    let id: Int
    let nombre: String?
    let descripcion: String?
    let horario_apertura: String?
    let horario_cierre: String?
    let limite_personas: Int?
    let cuota_por_uso: String?

    var cuotaPorUsoValor: Double {
        Double(cuota_por_uso ?? "") ?? 0
    }
}

struct Reserva: Codable, Identifiable {
    let id: Int
    let titulo: String?
    let fecha_inicio: String?
    let fecha_fin: String?
    let hora_inicio: String?
    let hora_fin: String?
    let descripcion: String?
    let area_comun_nombre: String?
    let adeudo_evento: AdeudoEvento?
    let reserva_residente: ReservaResidente?
}

struct AdeudoEvento: Codable {
    let estatus_pago: EstatusPago?
}

struct EstatusPago: Codable {
    let id: Int?
    let descripcion: String?
}

struct ReservaResidente: Codable {
    let nombre_completo: String?
}

struct AreasComunesResponse: Codable {
    let success: Bool?
    let total: Int?
    let data: [AreaComun]?
}

struct ReservasResponse: Codable {
    let success: Bool?
    let dias_apartados: [String]?
    let mis_reservas: [Reserva]?
}

struct EventoErrorResponse: Codable {
    let success: Bool?
    let message: String?
}

struct CreateEventoSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @Binding var isPresented: Bool
    @State private var tituloEvento = ""
    @State private var fechaEvento = Date()
    @State private var horaInicio = Date()
    @State private var horaFin = Date()
    @State private var descripcion = ""
    @State private var isSubmitting = false
    @State private var errorAlert: ErrorPeticionMensaje?
    @State private var showResumen = false
    let area: AreaComun
    let fechaPreseleccionada: Date
    let onEventoCreated: () -> Void

    var ubicacionTexto: String {
        authService.user?.ubicaciones.first?.value ?? "N/A"
    }

    var residenteTexto: String {
        "\(authService.user?.first_name ?? "") \(authService.user?.last_name ?? "")"
    }

    var is36HorasValido: Bool {
        let hoursInFuture = fechaEvento.timeIntervalSince(Date()) / 3600
        return hoursInFuture >= 36
    }

    var fechaMinima: Date {
        Date().addingTimeInterval(36 * 3600)
    }

    var duracionEnHoras: Double {
        horaFin.timeIntervalSince(horaInicio) / 3600
    }

    var duracionValida: Bool {
        duracionEnHoras > 0 && duracionEnHoras <= 5
    }

    private func mostrarToast(_ mensaje: String) {
        errorAlert = ErrorPeticionMensaje(mensaje: mensaje)
    }

    var body: some View {
        ZStack(alignment: .top) {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Reservar área")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .borderBottom()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            Text("Información de la Reserva")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Área Común")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(area.nombre ?? "")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ubicación y residente")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ubicacionTexto)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(residenteTexto)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Título del evento")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        TextField("Evento Privado", text: $tituloEvento)
                            .font(.system(size: 16))
                            .padding(12)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            Text("Fecha y Horario")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fecha")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)

                            DatePicker("", selection: $fechaEvento, in: fechaMinima..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .environment(\.locale, Locale(identifier: "es_ES"))
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Inicio")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: $horaInicio, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .onChange(of: horaInicio) { _, nuevoInicio in
                                        horaFin = nuevoInicio.addingTimeInterval(5 * 3600)
                                    }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fin")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: $horaFin, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                            }
                        }

                        Text("Las reservas requieren un mínimo de 36 horas de anticipación. La duración máxima de un evento es de 5 horas.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            Text("Detalles Adicionales")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        TextEditor(text: $descripcion)
                            .font(.system(size: 16))
                            .frame(height: 100)
                            .padding(12)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }

                    Button(action: {
                        guard duracionValida else {
                            mostrarToast("La duración máxima de un evento es de 5 horas")
                            return
                        }
                        showResumen = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                            Text("Guardar Evento")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting || tituloEvento.isEmpty || !is36HorasValido)
                }
                .padding(16)
            }
            }
            .background(Color.appBackground)
        }
        .sheet(item: $errorAlert) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: { errorAlert = nil })
                .presentationDetents([.fraction(0.45)])
        }
        .onAppear {
            let validDate = max(fechaPreseleccionada, fechaMinima)
            fechaEvento = validDate
            horaFin = horaInicio.addingTimeInterval(5 * 3600)
        }
        .sheet(isPresented: $showResumen) {
            ResumenReservaSheet(
                area: area,
                ubicacionTexto: ubicacionTexto,
                fecha: fechaEvento,
                horaInicio: horaInicio,
                horaFin: horaFin,
                tituloEvento: tituloEvento,
                descripcion: descripcion,
                onConfirm: {
                    isSubmitting = true
                    Task {
                        await createEvento()
                    }
                }
            )
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
        }
    }

    private func createEvento() async {
        guard let ubicacionIdStr = authService.user?.ubicaciones.first?.key,
              let ubicacionId = Int(ubicacionIdStr) else {
            isSubmitting = false
            showResumen = false
            mostrarToast("No se pudo determinar la ubicación")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let fechaStr = formatter.string(from: fechaEvento)

        let horaFormatter = DateFormatter()
        horaFormatter.dateFormat = "HH:mm"
        let horaInicioStr = horaFormatter.string(from: horaInicio)
        let horaFinStr = horaFormatter.string(from: horaFin)

        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/eventos") else {
            isSubmitting = false
            showResumen = false
            mostrarToast("URL inválida")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let params: [String: Any] = [
            "area_comun_id": area.id,
            "ubicacion_id": ubicacionId,
            "fecha": fechaStr,
            "nombre_evento": tituloEvento,
            "hora_inicio": horaInicioStr,
            "hora_fin": horaFinStr,
            "descripcion": descripcion
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            if statusCode >= 200 && statusCode < 300 {
                await MainActor.run {
                    isSubmitting = false
                    onEventoCreated()
                    dismiss()
                }
            } else {
                let mensaje = (try? JSONDecoder().decode(EventoErrorResponse.self, from: data))?.message
                    ?? "No se pudo guardar la reservación"
                print("❌ Error del servidor al crear evento (\(statusCode)): \(mensaje)")
                await MainActor.run {
                    isSubmitting = false
                    showResumen = false
                    mostrarToast(mensaje)
                }
            }
        } catch {
            print("❌ Error creating evento: \(error)")
            await MainActor.run {
                isSubmitting = false
                showResumen = false
                mostrarToast("No se pudo guardar la reservación")
            }
        }
    }
}

struct ResumenReservaSheet: View {
    @Environment(\.dismiss) var dismiss
    let area: AreaComun
    let ubicacionTexto: String
    let fecha: Date
    let horaInicio: Date
    let horaFin: Date
    let tituloEvento: String
    let descripcion: String
    let onConfirm: () -> Void

    private var fechaStr: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: fecha)
    }

    private var horarioStr: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: horaInicio)) - \(formatter.string(from: horaFin))"
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                    .cornerRadius(10)
                Text("Resumen de Reserva")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                                .foregroundColor(.green)
                            Text(area.nombre ?? "")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }

                        HStack(alignment: .top) {
                            ResumenCampo(label: "Apertura", value: area.horario_apertura ?? "N/A")
                            ResumenCampo(label: "Cierre", value: area.horario_cierre ?? "N/A")
                            ResumenCampo(label: "Capacidad", value: area.limite_personas.map { "\($0)" } ?? "N/A")
                            ResumenCampo(label: "Costo", value: "$\(String(format: "%.2f", area.cuotaPorUsoValor))")
                        }
                    }
                    .padding(16)
                    .background(Color.greenTint)
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            ResumenCampo(label: "Ubicación", value: ubicacionTexto, bold: true)
                            ResumenCampo(label: "Fecha", value: fechaStr, bold: true)
                        }
                        HStack(alignment: .top) {
                            ResumenCampo(label: "Horario", value: horarioStr, bold: true)
                            ResumenCampo(label: "Evento", value: tituloEvento.isEmpty ? "Evento Privado" : tituloEvento, bold: true)
                        }
                        if !descripcion.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Detalles adicionales")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(descripcion)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background(Color.selectedTint)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
            }

            VStack(spacing: 12) {
                Button(action: { onConfirm() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirmar y Enviar")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                    .cornerRadius(12)
                }

                Button(action: { dismiss() }) {
                    Text("Volver a editar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.selectedTint)
                        .cornerRadius(12)
                }
            }
            .padding(16)
        }
        .background(Color.appBackground)
    }
}

struct ResumenCampo: View {
    let label: String
    let value: String
    var bold: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: bold ? .bold : .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DetalleReservaSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    let evento: Reserva

    private var estatusTexto: String {
        evento.adeudo_evento?.estatus_pago?.descripcion ?? "Pendiente"
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            HStack {
                Text("Detalle de la Reserva")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(evento.titulo ?? "Evento")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        if let areaNombre = evento.area_comun_nombre {
                            Text(areaNombre)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }

                    Divider()

                    VStack(spacing: 12) {
                        DetalleFila(label: "Fecha", value: evento.fecha_inicio ?? "N/A")
                        DetalleFila(label: "Horario", value: "\(evento.hora_inicio ?? "")  - \(evento.hora_fin ?? "")")
                        DetalleFila(label: "Ubicación", value: authService.user?.ubicaciones.first?.value ?? "N/A", boldValue: true)
                        DetalleFila(label: "Residente", value: evento.reserva_residente?.nombre_completo ?? "N/A")
                        DetalleFila(label: "Estatus Pago", value: estatusTexto, boldValue: true)
                    }

                    if let descripcion = evento.descripcion, !descripcion.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Descripción")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Text(descripcion)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(16)
                .background(Color.blueTint)
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

            Button(action: { dismiss() }) {
                Text("Cerrar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.selectedTint)
                    .cornerRadius(12)
            }
            .padding(16)
        }
        .background(Color.appBackground)
    }
}

struct DetalleFila: View {
    let label: String
    let value: String
    var boldValue: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: boldValue ? .bold : .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview { EventosView().environmentObject(AuthService(mockData: true)) }
