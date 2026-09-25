import SwiftUI

struct MensualidadesDetailView: View {
    let year: Int
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = MensualidadesDetailViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Mensualidades \(String(year))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ubicación")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Text(viewModel.direccion.isEmpty ? (authService.user?.ubicaciones.first?.value ?? "N/A") : viewModel.direccion)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

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
                        }

                        HStack(spacing: 12) {
                            StatBox(label: "CUOTA ANUAL", value: viewModel.totales?.cuota ?? 0, color: .primary)
                            StatBox(label: "TOTAL PAGADO", value: viewModel.totales?.pagado ?? 0, color: Color.statusSuccess)
                            StatBox(label: "RESTA TOTAL", value: viewModel.totales?.resta ?? 0, color: Color.statusError)
                        }

                        VStack(spacing: 0) {
                            HStack {
                                Text("MES")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("CUOTA")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("PAGADO")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("RESTA")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("STATUS")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.bottom, 12)

                            ForEach(viewModel.mensualidades) { mes in
                                VStack(spacing: 0) {
                                    HStack {
                                        Text(mes.mes)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("$\(String(format: "%.2f", mes.cuota))")
                                            .font(.system(size: 10))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("$\(String(format: "%.2f", mes.pagado))")
                                            .font(.system(size: 10))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text("$\(String(format: "%.2f", mes.resta))")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(estatusColor(mes.estatus))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(mes.estatus)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(estatusColor(mes.estatus))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(estatusColor(mes.estatus).opacity(0.1))
                                            .cornerRadius(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 12)

                                    if mes.id != viewModel.mensualidades.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            guard let ubicacionId = Int(authService.user?.ubicaciones.first?.key ?? "") else { return }
            Task {
                await viewModel.loadMensualidades(ubicacionId: ubicacionId, anio: year)
            }
        }
    }

    private func estatusColor(_ estatus: String) -> Color {
        switch estatus {
        case "Pagado":
            return Color.statusSuccess
        case "Parcial", "Por validar":
            return Color.statusWarning
        default:
            return Color.statusError
        }
    }
}

private struct StatBox: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            Text("$\(String(format: "%.2f", value))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    MensualidadesDetailView(year: 2026)
        .environmentObject(AuthService(mockData: true))
}
