import SwiftUI

struct CensoView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CensoViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Censo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
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
                        // Ubicación
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("UBICACIÓN")
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
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal, 16)

                        // Descripción
                        Text("Captura cuántas personas viven en esta unidad. Esta información ayuda a la administración a planear servicios y espacios comunes.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 16) {
                            CensoFieldView(label: "RESIDENTES", icon: "👥", value: $viewModel.residentes)
                            CensoFieldView(label: "MENORES DE EDAD", icon: "👶", value: $viewModel.menores)
                            CensoFieldView(label: "ADULTOS MAYORES", icon: "👴", value: $viewModel.adultosMayores)
                        }
                        .padding(.horizontal, 16)

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

                        Button(action: {
                            guard let ubicacionId = authService.user?.ubicaciones.first?.key else { return }
                            Task {
                                await viewModel.saveCenso(ubicacionId: ubicacionId)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Guardar")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isSaving)
                        .padding(.horizontal, 16)
                    }

                    Spacer()
                }
            }
        }
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
        .onAppear {
            guard let ubicacionId = authService.user?.ubicaciones.first?.key else { return }
            Task {
                await viewModel.loadCenso(ubicacionId: ubicacionId)
            }
        }
    }
}

struct CensoFieldView: View {
    let label: String
    let icon: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }

            TextField("0", text: $value)
                .font(.system(size: 32, weight: .semibold))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    CensoView()
        .environmentObject(AuthService(mockData: true))
}
