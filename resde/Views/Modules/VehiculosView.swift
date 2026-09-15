import SwiftUI

struct VehiculosView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = VehiculosViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        ZStack {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Vehículos")
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
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Descripción
                    Text("Registra hasta 4 vehículos asociados a esta unidad. Solo es obligatorio llenar los datos del vehículo que vayas a registrar.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)

                    // Formulario de vehículos
                    VStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 12) {
                                Text("VEHÍCULO \(index + 1)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)

                                // Marca
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Marca")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Menu {
                                        Button(action: { viewModel.vehiculos[index].marcaAutoId = nil }) {
                                            Text("--")
                                        }
                                        ForEach(viewModel.brands, id: \.id) { brand in
                                            Button(action: { viewModel.vehiculos[index].marcaAutoId = brand.id }) {
                                                Text(brand.descripcion)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(viewModel.vehiculos[index].marcaAutoId == nil ? "Seleccione una marca" : (viewModel.brands.first { $0.id == viewModel.vehiculos[index].marcaAutoId }?.descripcion ?? "Seleccione una marca"))
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.blue)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(16)
                                        .background(Color.cardBackground)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.0, green: 0.4, blue: 0.7), lineWidth: 2))
                                    }
                                }

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Color")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        TextField("Color", text: $viewModel.vehiculos[index].color)
                                            .font(.system(size: 14))
                                            .padding(12)
                                            .background(Color.cardBackground)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Placa")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                        TextField("Placa", text: $viewModel.vehiculos[index].placa)
                                            .font(.system(size: 14))
                                            .padding(12)
                                            .background(Color.cardBackground)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
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

                    // Botón Guardar
                    Button(action: {
                        guard let ubicacionIdStr = authService.user?.ubicaciones.first?.key,
                              let ubicacionId = Int(ubicacionIdStr) else { return }
                        Task {
                            await viewModel.saveVehiculos(ubicacionId: ubicacionId)
                        }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                            }
                            Text(viewModel.isSaving ? "Guardando..." : "Guardar")
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
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            guard let ubicacionId = Int(authService.user?.ubicaciones.first?.key ?? "") else { return }
            Task {
                await viewModel.loadVehiculos(ubicacionId: ubicacionId)
            }
        }

        VStack {
            Spacer()
            if viewModel.showSuccessToast {
                SuccessToast(message: viewModel.successMessage)
            }
        }
        }
    }
}

#Preview {
    VehiculosView()
        .environmentObject(AuthService(mockData: true))
}
