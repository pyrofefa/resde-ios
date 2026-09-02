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
                        Text("Reporte Financiero")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
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
                                .background(Color.white)
                                .cornerRadius(8)
                            }
                            .padding(16)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                        } else {
                            VStack(alignment: .center, spacing: 8) {
                                Text("RESUMEN FINANCIERO")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text("Este mes aún no ha sido publicado.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                        }

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
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
        .onAppear {
            Task {
                await viewModel.loadReportes()
            }
        }
    }
}

#Preview {
    ReportesView()
}
