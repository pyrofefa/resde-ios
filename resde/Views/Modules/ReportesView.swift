import SwiftUI
import Charts

private func formatMonto(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    return "$" + (formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value))
}

private func formatFechaLarga(_ iso: String) -> String {
    let parser = DateFormatter()
    parser.dateFormat = "yyyy-MM-dd"
    guard let date = parser.date(from: iso) else { return iso }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "es_MX")
    formatter.dateFormat = "dd 'de' MMMM 'del' yyyy"
    return formatter.string(from: date)
}

struct ReportesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ReportesViewModel()
    @State private var showMesAnioPicker = false
    @State private var showDetalleMovimientos = false

    var body: some View {
        ZStack {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Reportes")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showMesAnioPicker = true }) {
                    Text(viewModel.monthYearString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Reporte financiero")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                if let rango = viewModel.resumenFinanciero?.rango_consultado,
                                   let desde = rango.desde, let hasta = rango.hasta {
                                    Text("\(formatFechaLarga(desde)) a \(formatFechaLarga(hasta))")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.trailing)
                                } else {
                                    Text("Este mes aún no ha sido publicado.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        if let resumen = viewModel.resumenFinanciero {
                            ResumenFinancieroCard(resumen: resumen, onVerDetalles: {
                                showDetalleMovimientos = true
                                Task {
                                    await viewModel.loadDetalleMovimientos()
                                }
                            })
                        } else {
                            ReporteCardVacio(title: "RESUMEN FINANCIERO")
                        }

                        ComparacionFuentesCard(grafica: viewModel.totalesGrafica)

                        ComparacionConceptosCard(
                            barrasIngresos: viewModel.barrasIngresos,
                            barrasEgresos: viewModel.barrasEgresos,
                            conceptoSeleccionado: $viewModel.conceptoSeleccionado
                        )

                        TendenciaCard(
                            tendenciaIngresos: viewModel.tendenciaIngresos,
                            tendenciaEgresos: viewModel.tendenciaEgresos
                        )

                        if viewModel.showError {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(viewModel.errorMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            Task {
                await viewModel.loadReportes()
            }
        }
        .sheet(isPresented: $showDetalleMovimientos) {
            DetalleMovimientosSheet(viewModel: viewModel)
        }

        if showMesAnioPicker {
            MesAnioPickerOverlay(
                selectedDate: viewModel.selectedDate,
                onCancel: { showMesAnioPicker = false },
                onAccept: { date in
                    viewModel.selectedDate = date
                    showMesAnioPicker = false
                    Task {
                        await viewModel.loadReportes()
                    }
                }
            )
        }
        }
    }
}

// MARK: - Resumen Financiero

private struct ResumenFinancieroCard: View {
    let resumen: BalanceMensualData
    let onVerDetalles: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESUMEN FINANCIERO")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Ingresos")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatMonto(resumen.ingresosValor))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.2))
                }

                HStack {
                    Text("Total Egresos")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatMonto(resumen.egresosValor))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                }

                Divider()

                HStack {
                    Text("Balance Neto")
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatMonto(resumen.balanceValor))
                        .fontWeight(.bold)
                        .foregroundColor(resumen.balanceValor >= 0 ? Color(red: 0.2, green: 0.7, blue: 0.2) : Color(red: 0.8, green: 0.2, blue: 0.2))
                }
            }
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(8)

            Button(action: onVerDetalles) {
                Text("Ver más detalles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Detalle de movimientos

private struct DetalleMovimientosSheet: View {
    @ObservedObject var viewModel: ReportesViewModel
    @Environment(\.dismiss) var dismiss
    @State private var tab: ConceptoReporte = .ingresos
    @State private var selectedMovimiento: MovimientoDetalle?

    private var movimientos: [MovimientoDetalle] {
        tab == .ingresos ? viewModel.tablaIngresos : viewModel.tablaEgresos
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Detalle de movimientos")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            HStack(spacing: 0) {
                Button(action: { tab = .ingresos }) {
                    Text("Ingresos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(tab == .ingresos ? Color.selectedTint : Color.clear)
                }
                Button(action: { tab = .egresos }) {
                    Text("Egresos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(tab == .egresos ? Color.selectedTint : Color.clear)
                }
            }
            .background(Color.cardBackground)
            .padding(16)

            if viewModel.isLoadingDetalle {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if movimientos.isEmpty {
                Text("Sin movimientos registrados.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(movimientos) { movimiento in
                            Button(action: { selectedMovimiento = movimiento }) {
                                MovimientoRow(movimiento: movimiento)
                            }
                            .buttonStyle(.plain)
                            if movimiento.id != movimientos.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.appBackground)
        .presentationDetents([.fraction(0.8)])
        .sheet(item: $selectedMovimiento) { movimiento in
            MovimientoDetalleSheet(
                movimiento: movimiento,
                tipoLabel: tab == .ingresos ? "INGRESO" : "EGRESO"
            )
            .presentationDetents([.fraction(0.55)])
        }
    }
}

private struct MovimientoDetalleSheet: View {
    let movimiento: MovimientoDetalle
    let tipoLabel: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Detalle del Movimiento")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(formatMonto(movimiento.montoValor))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    Text((movimiento.tipo ?? tipoLabel).uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 12) {
                    DetalleMovimientoFila(label: "Folio", valor: movimiento.folio ?? "-")
                    DetalleMovimientoFila(label: "Fecha", valor: movimiento.fecha ?? "-")
                    DetalleMovimientoFila(label: "Concepto", valor: movimiento.concepto ?? "-")
                    DetalleMovimientoFila(label: "Pago", valor: movimiento.forma_metodo_pago ?? "-")
                }
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

            Button(action: { dismiss() }) {
                Text("Cerrar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.selectedTint)
                    .cornerRadius(25)
            }
        }
        .padding(20)
        .background(Color.appBackground)
    }
}

private struct DetalleMovimientoFila: View {
    let label: String
    let valor: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(valor)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct MovimientoRow: View {
    let movimiento: MovimientoDetalle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(movimiento.folio ?? "-")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                Spacer()
                Text(formatMonto(movimiento.montoValor))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            Text(movimiento.concepto ?? "")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            HStack {
                Text(movimiento.fecha ?? "")
                Spacer()
                if let metodo = movimiento.forma_metodo_pago {
                    Text(metodo)
                }
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding(16)
    }
}

// MARK: - Comparación de fuentes de ingreso (pastel)

private struct PieSlice: Identifiable {
    let id = UUID()
    let label: String
    let monto: Double
    let color: Color
}

private struct ComparacionFuentesCard: View {
    let grafica: TotalesGraficaData?

    private var slices: [PieSlice] {
        guard let grafica = grafica else { return [] }
        return [
            PieSlice(label: "Ingresos", monto: grafica.ingresosValor, color: .blue),
            PieSlice(label: "Egresos", monto: grafica.egresosValor, color: Color(red: 0.2, green: 0.7, blue: 0.2))
        ].filter { $0.monto > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPARACIÓN DE FUENTES DE INGRESO")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            if slices.isEmpty {
                Text("Este mes aún no ha sido publicado.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .multilineTextAlignment(.center)
            } else {
                Chart(slices) { slice in
                    SectorMark(angle: .value("Monto", slice.monto), angularInset: 1.5)
                        .foregroundStyle(slice.color)
                        .annotation(position: .overlay) {
                            VStack(spacing: 2) {
                                Text(formatMonto(slice.monto))
                                    .font(.system(size: 13, weight: .bold))
                                Text(slice.label)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white)
                        }
                }
                .frame(height: 240)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Comparación por conceptos (barras + tabla)

private struct ComparacionConceptosCard: View {
    let barrasIngresos: [BarraConcepto]
    let barrasEgresos: [BarraConcepto]
    @Binding var conceptoSeleccionado: ConceptoReporte

    private var barrasActuales: [BarraConcepto] {
        conceptoSeleccionado == .ingresos ? barrasIngresos : barrasEgresos
    }

    private var colorBarra: Color {
        conceptoSeleccionado == .ingresos ? .blue : Color(red: 0.2, green: 0.7, blue: 0.2)
    }

    private var prefijoClave: String {
        conceptoSeleccionado == .ingresos ? "IN" : "EG"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPARACIÓN POR CONCEPTOS")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            HStack(spacing: 0) {
                Button(action: { conceptoSeleccionado = .ingresos }) {
                    Text("Ingresos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(conceptoSeleccionado == .ingresos ? Color.selectedTint : Color.clear)
                }
                Button(action: { conceptoSeleccionado = .egresos }) {
                    Text("Egresos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(conceptoSeleccionado == .egresos ? Color.selectedTint : Color.clear)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 1))

            if barrasActuales.isEmpty {
                Text("Este mes aún no ha sido publicado.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .multilineTextAlignment(.center)
            } else {
                Chart(Array(barrasActuales.enumerated()), id: \.element.id) { index, item in
                    BarMark(
                        x: .value("Concepto", "\(prefijoClave)\(index + 1)"),
                        y: .value("Monto", item.montoValor)
                    )
                    .foregroundStyle(colorBarra)
                }
                .frame(height: 200)

                VStack(spacing: 0) {
                    HStack {
                        Text("CLAVE")
                            .frame(width: 60, alignment: .leading)
                        Text("CONCEPTO")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("MONTO")
                            .frame(alignment: .trailing)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.05, green: 0.2, blue: 0.35))

                    ForEach(Array(barrasActuales.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            Text("\(prefijoClave)\(index + 1)")
                                .frame(width: 60, alignment: .leading)
                            Text(item.concepto ?? "")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(formatMonto(item.montoValor))
                                .fontWeight(.semibold)
                                .frame(alignment: .trailing)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if item.id != barrasActuales.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Tendencia de ingresos y egresos (líneas)

private struct TendenciaCard: View {
    let tendenciaIngresos: [PuntoTendencia]
    let tendenciaEgresos: [PuntoTendencia]

    private var vacio: Bool {
        tendenciaIngresos.isEmpty && tendenciaEgresos.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TENDENCIA DE INGRESOS Y EGRESOS")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            if vacio {
                Text("Este mes aún no ha sido publicado.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .multilineTextAlignment(.center)
            } else {
                Chart {
                    ForEach(tendenciaIngresos.filter { $0.fechaDate != nil }) { punto in
                        LineMark(
                            x: .value("Fecha", punto.fechaDate!),
                            y: .value("Monto", punto.montoValor)
                        )
                        .foregroundStyle(by: .value("Tipo", "Ingresos"))
                        .symbol(by: .value("Tipo", "Ingresos"))
                    }
                    ForEach(tendenciaEgresos.filter { $0.fechaDate != nil }) { punto in
                        LineMark(
                            x: .value("Fecha", punto.fechaDate!),
                            y: .value("Monto", punto.montoValor)
                        )
                        .foregroundStyle(by: .value("Tipo", "Egresos"))
                        .symbol(by: .value("Tipo", "Egresos"))
                    }
                }
                .chartForegroundStyleScale([
                    "Ingresos": Color.blue,
                    "Egresos": Color(red: 0.2, green: 0.7, blue: 0.2)
                ])
                .frame(height: 220)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct MesAnioPickerOverlay: View {
    let selectedDate: Date
    let onCancel: () -> Void
    let onAccept: (Date) -> Void

    @State private var tempMonth: Int
    @State private var tempYear: Int

    private let months = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"]
    private let years: [Int]

    init(selectedDate: Date, onCancel: @escaping () -> Void, onAccept: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.onCancel = onCancel
        self.onAccept = onAccept
        let calendar = Calendar.current
        _tempMonth = State(initialValue: calendar.component(.month, from: selectedDate))
        _tempYear = State(initialValue: calendar.component(.year, from: selectedDate))
        let currentYear = calendar.component(.year, from: Date())
        self.years = Array((currentYear - 10)...currentYear).reversed()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(alignment: .leading, spacing: 16) {
                Text("Seleccionar Mes y Año")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                HStack(spacing: 0) {
                    Picker("Mes", selection: $tempMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(months[month - 1])
                                .font(.system(size: 20, weight: month == tempMonth ? .bold : .regular))
                                .foregroundColor(.primary)
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)

                    Picker("Año", selection: $tempYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year))
                                .font(.system(size: 20, weight: year == tempYear ? .bold : .regular))
                                .foregroundColor(.primary)
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 160)
                .clipped()

                HStack {
                    Spacer()
                    Button(action: onCancel) {
                        Text("CANCELAR")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        var components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
                        components.year = tempYear
                        components.month = tempMonth
                        components.day = 1
                        let newDate = Calendar.current.date(from: components) ?? selectedDate
                        onAccept(newDate)
                    }) {
                        Text("ACEPTAR")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(Color.cardBackground)
            .cornerRadius(4)
            .frame(maxWidth: 320)
            .padding(.horizontal, 32)
        }
    }
}

struct ReporteCardVacio: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Text("Este mes aún no ha sido publicado.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, minHeight: 160)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    ReportesView()
}
