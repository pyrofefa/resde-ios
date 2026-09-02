import SwiftUI

struct ReportesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ReportesViewModel()

    var body: some View {
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
                Text(viewModel.monthYearString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(8)
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
