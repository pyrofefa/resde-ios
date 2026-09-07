//
//  MensualidadesView.swift
//  resde
//

import SwiftUI

struct MensualidadesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MensualidadesViewModel()
    @EnvironmentObject var authService: AuthService

    private var deudaColor: Color {
        viewModel.deudaTotalAcumulada <= 0 ? Color(red: 0.2, green: 0.7, blue: 0.2) : Color(red: 0.8, green: 0.2, blue: 0.2)
    }

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeader(title: "Estado de Deuda")

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

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else {
                        VStack(spacing: 8) {
                            Text("DEUDA TOTAL ACUMULADA")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(deudaColor)
                            Text("$\(String(format: "%.2f", viewModel.deudaTotalAcumulada))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(deudaColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(24)
                        .background(viewModel.deudaTotalAcumulada <= 0 ? Color(red: 0.9, green: 0.98, blue: 0.9) : Color.redTint)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                        ForEach(viewModel.years, id: \.self) { year in
                            NavigationLink(destination: MensualidadesDetailView(year: year)) {
                                YearDebtCard(year: year, totales: viewModel.totalesPorAnio[year])
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            guard let ubicacionId = Int(authService.user?.ubicaciones.first?.key ?? "") else { return }
            Task {
                await viewModel.loadResumen(ubicacionId: ubicacionId)
            }
        }
    }
}

struct YearDebtCard: View {
    let year: Int
    let totales: MensualidadTotales?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(year))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Adeudo de este año")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Pagado: $\(String(format: "%.2f", totales?.pagado ?? 0))")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.2))
                    HStack(spacing: 4) {
                        Text("$\(String(format: "%.2f", totales?.resta ?? 0))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    Text("Ver detalle")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    MensualidadesView()
        .environmentObject(AuthService(mockData: true))
}
