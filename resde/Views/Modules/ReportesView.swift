import SwiftUI

struct ReportesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ReportesViewModel()
    @State private var showMesAnioPicker = false

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
                                Text(viewModel.resumenFinanciero == nil ? "Este mes aún no ha sido publicado." : "Publicado")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)

                        if let resumen = viewModel.resumenFinanciero {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("RESUMEN FINANCIERO")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Ingresos:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("$\(resumen.total_ingresos_mes)")
                                            .fontWeight(.semibold)
                                    }

                                    HStack {
                                        Text("Egresos:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("$\(resumen.total_egresos_mes)")
                                            .fontWeight(.semibold)
                                    }

                                    Divider()

                                    HStack {
                                        Text("Balance Neto:")
                                            .foregroundColor(.secondary)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("$\(resumen.balance_neto)")
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(12)
                                .background(Color.cardBackground)
                                .cornerRadius(8)
                            }
                            .padding(16)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        } else {
                            ReporteCardVacio(title: "RESUMEN FINANCIERO")
                        }

                        ReporteCardVacio(title: "COMPARACIÓN DE FUENTES DE INGRESO")

                        VStack(alignment: .leading, spacing: 12) {
                            Text("COMPARACIÓN POR CONCEPTOS")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 0) {
                                Button(action: { viewModel.conceptoSeleccionado = .ingresos }) {
                                    Text("Ingresos")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(viewModel.conceptoSeleccionado == .ingresos ? Color.selectedTint : Color.clear)
                                }
                                Button(action: { viewModel.conceptoSeleccionado = .egresos }) {
                                    Text("Egresos")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(viewModel.conceptoSeleccionado == .egresos ? Color.selectedTint : Color.clear)
                                }
                            }
                            .background(Color.cardBackground)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 1))

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

                        ReporteCardVacio(title: "TENDENCIA DE INGRESOS Y EGRESOS")

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
