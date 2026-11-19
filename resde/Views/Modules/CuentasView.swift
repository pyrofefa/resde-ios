import SwiftUI

struct CuentasView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CuentasViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showNuevaCuenta = false
    @State private var toastMensaje: String?

    private var ubicacionNombre: String {
        authService.ubicacionActualNombre ?? "N/A"
    }

    private func recargar() async {
        guard let id = authService.ubicacionActualId else { return }
        await viewModel.loadCuentas(ubicacionId: id)
    }

    private func accionCompletada(_ mensaje: String) {
        viewModel.selectedCuenta = nil
        withAnimation { toastMensaje = mensaje }
        Task {
            await recargar()
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { toastMensaje = nil }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Cuentas Vinculadas")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UBICACIÓN")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(ubicacionNombre)
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

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Buscar por nombre o correo", text: $viewModel.searchText)
                            .font(.system(size: 15))
                    }
                    .padding(12)
                    .background(Color.cardBackground)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else {
                        Text("\(viewModel.filteredCuentas.count) cuenta(s) vinculada(s)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredCuentas) { cuenta in
                                Button(action: { viewModel.selectedCuenta = cuenta }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(cuenta.nombre_completo)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Text(cuenta.email)
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(16)
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 90)
            }
            .refreshable { await recargar() }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .sheet(item: $viewModel.selectedCuenta) { cuenta in
            CuentaDetailSheet(cuenta: cuenta, viewModel: viewModel, onActualizado: accionCompletada)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNuevaCuenta) {
            NuevaCuentaSheet(
                viewModel: viewModel,
                ubicacionId: authService.ubicacionActualId ?? 0,
                ubicacionNombre: ubicacionNombre,
                isPresented: $showNuevaCuenta,
                onCreada: accionCompletada
            )
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: { showNuevaCuenta = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Nueva Cuenta")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.accionPrimaria)
                .cornerRadius(28)
            }
            .padding(16)
            .disabled(authService.ubicacionActualId == nil)
        }
        .overlay(alignment: .bottom) {
            if let mensaje = toastMensaje {
                SuccessToast(message: mensaje)
                    .padding(.bottom, 80)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            Task { await recargar() }
        }
    }
}

#Preview {
    CuentasView()
        .environmentObject(AuthService(mockData: true))
}
