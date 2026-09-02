import SwiftUI

struct MascotasView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MascotasViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Mascotas")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Ubicación
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
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Descripción
                    Text("Indica el número de mascotas que habitan en esta unidad. Solo es obligatorio si tienes mascotas.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)

                    // Perros
                    MascotaCounterCard(
                        icon: "🐕",
                        title: "PERROS",
                        value: $viewModel.perros
                    )
                    .padding(.horizontal, 16)

                    // Gatos
                    MascotaCounterCard(
                        icon: "🐈",
                        title: "GATOS",
                        value: $viewModel.gatos
                    )
                    .padding(.horizontal, 16)

                    // Otras especies
                    MascotaCounterCard(
                        icon: "🐾",
                        title: "OTRAS ESPECIES",
                        value: $viewModel.otrasEspecies
                    )
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

                    // Botón Guardar
                    Button(action: {
                        guard let ubicacionIdStr = authService.user?.ubicaciones.first?.key,
                              let ubicacionId = Int(ubicacionIdStr) else { return }
                        Task {
                            await viewModel.saveMascotas(ubicacionId: ubicacionId)
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

                    Spacer()
                }
            }
        }
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
        .onAppear {
            guard let ubicacionId = Int(authService.user?.ubicaciones.first?.key ?? "") else { return }
            Task {
                await viewModel.loadMascotas(ubicacionId: ubicacionId)
            }
        }
    }
}

struct MascotaCounterCard: View {
    let icon: String
    let title: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                Text(title)
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
    MascotasView()
        .environmentObject(AuthService(mockData: true))
}
