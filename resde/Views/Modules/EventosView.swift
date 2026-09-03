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
    @State private var toastMessage = ""
    @State private var showToast = false

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

    var fechaMinima: Date {
        Date().addingTimeInterval(36 * 3600)
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
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                }
                                Button(action: { changeMonth(by: 1) }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 16))
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
                                    toastMessage = "La reserva debe ser con mínimo 36 horas de anticipación"
                                    showToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showToast = false
                                    }
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
                                        EventoCard(evento: evento)
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
                if showToast {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.white)
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(16)
                }

                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCreateEvento = true
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
            let (data, _) = try await URLSession.shared.data(for: request)
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
            let (data, _) = try await URLSession.shared.data(for: request)
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
                    } else if !isOccupied {
                        selectedDate = dayDate
                        displayMonth = dayDate
                    }
                }) {
                    DayCellContent(dayNum: dayNum, isSelected: isSelected, isDisabled: isDisabled)
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
    let isDisabled: Bool

    var body: some View {
        Text(String(dayNum))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isDisabled ? .gray : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
}

struct EventoCard: View {
    let evento: Reserva

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(evento.titulo ?? "Evento")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(evento.hora_inicio ?? "")  - \(evento.hora_fin ?? "")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
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
}

struct Reserva: Codable, Identifiable {
    let id: Int
    let titulo: String?
    let fecha_inicio: String?
    let fecha_fin: String?
    let hora_inicio: String?
    let hora_fin: String?
    let descripcion: String?
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
    let area: AreaComun
    let fechaPreseleccionada: Date
    let onEventoCreated: () -> Void

    var is36HorasValido: Bool {
        let hoursInFuture = fechaEvento.timeIntervalSince(Date()) / 3600
        return hoursInFuture >= 36
    }

    var fechaMinima: Date {
        Date().addingTimeInterval(36 * 3600)
    }

    var body: some View {
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
                                Text("Juan Rulfo #11")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(authService.user?.first_name ?? "" + " " + (authService.user?.last_name ?? ""))
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
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fin")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: $horaFin, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                            }
                        }

                        Text("Las reservas requieren un mínimo de 36 horas de anticipación.")
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
                        isSubmitting = true
                        Task {
                            await createEvento()
                        }
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
        .onAppear {
            let validDate = max(fechaPreseleccionada, fechaMinima)
            fechaEvento = validDate
        }
    }

    private func createEvento() async {
        guard let ubicacionId = authService.user?.ubicaciones.first?.key else {
            isSubmitting = false
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

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                await MainActor.run {
                    isSubmitting = false
                    onEventoCreated()
                    dismiss()
                }
            }
        } catch {
            print("❌ Error creating evento: \(error)")
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
}

#Preview { EventosView().environmentObject(AuthService(mockData: true)) }
