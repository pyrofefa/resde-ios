import SwiftUI

struct MascotasView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MascotasViewModel()
    @EnvironmentObject var authService: AuthService

    @State private var formulario: FormularioMascota?
    @State private var mascotaABaja: Mascota?
    @State private var toast: String?
    @State private var errorAlert: ErrorPeticionMensaje?

    private var ubicacionId: Int? { authService.ubicacionActualId }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ubicacionCard

                        HStack(spacing: 6) {
                            Text("MASCOTAS REGISTRADAS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("(\(viewModel.mascotas.count))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)

                        contenido
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 80)
                }
                .refreshable { await recargar() }
            }
            .background(Color.appBackground)

            botonAgregar

            if let toast {
                SuccessToast(message: toast)
                    .padding(.bottom, 76)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if viewModel.isWorking {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.4)
            }
        }
        .navigationBarBackButtonHidden()
        .task(id: ubicacionId) { await recargar() }
        .onChange(of: viewModel.successMessage) { _, mensaje in
            guard let mensaje else { return }
            mostrarToast(mensaje)
            viewModel.successMessage = nil
        }
        .onChange(of: viewModel.errorMessage) { _, mensaje in
            if let mensaje { errorAlert = ErrorPeticionMensaje(mensaje: mensaje) }
        }
        .sheet(item: $formulario) { contexto in
            MascotaFormSheet(
                viewModel: viewModel,
                mascota: contexto.mascota,
                onGuardada: { mensaje in
                    mostrarToast(mensaje)
                    Task { await recargar() }
                }
            )
            .environmentObject(authService)
        }
        .sheet(item: $errorAlert) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: {
                errorAlert = nil
                viewModel.errorMessage = nil
            })
            .presentationDetents([.fraction(0.45)])
        }
        .alert("Dar de baja mascota", isPresented: Binding(
            get: { mascotaABaja != nil },
            set: { if !$0 { mascotaABaja = nil } }
        )) {
            Button("Cancelar", role: .cancel) { mascotaABaja = nil }
            Button("Sí, dar de baja", role: .destructive) {
                if let mascota = mascotaABaja {
                    mascotaABaja = nil
                    Task { await viewModel.darDeBaja(mascota) }
                }
            }
        } message: {
            Text("¿Estás seguro de dar de baja a \(mascotaABaja?.nombre ?? "")?")
        }
    }

    // MARK: - Partes

    private var header: some View {
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
    }

    private var ubicacionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text("Ubicación")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(authService.ubicacionActualNombre ?? "N/A")
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
    }

    @ViewBuilder
    private var contenido: some View {
        if viewModel.isLoading && viewModel.mascotas.isEmpty {
            SeccionCargando(logo: authService.user?.logo, height: 160)
                .frame(maxWidth: .infinity)
        } else if viewModel.mascotas.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.gray.opacity(0.6))
                Text("No hay mascotas registradas")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Agrega las mascotas que habitan en esta ubicación usando el botón inferior.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            VStack(spacing: 10) {
                ForEach(viewModel.mascotas) { mascota in
                    MascotaFila(
                        mascota: mascota,
                        onTap: { formulario = FormularioMascota(mascota: mascota) },
                        onEliminar: { mascotaABaja = mascota }
                    )
                }
            }
        }
    }

    private var botonAgregar: some View {
        Button(action: { formulario = FormularioMascota(mascota: nil) }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Agregar Mascota")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color(red: 0.0, green: 0.4, blue: 0.7))
            .cornerRadius(25)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .disabled(viewModel.isWorking)
    }

    // MARK: - Acciones

    private func recargar() async {
        guard let id = ubicacionId else { return }
        await viewModel.cargarMascotas(ubicacionId: id)
    }

    private func mostrarToast(_ mensaje: String) {
        withAnimation { toast = mensaje }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { toast = nil }
        }
    }
}

/// Contexto del formulario: `mascota == nil` es alta; con valor, edición.
struct FormularioMascota: Identifiable {
    let id = UUID()
    let mascota: Mascota?
}

// MARK: - Fila

private struct MascotaFila: View {
    let mascota: Mascota
    let onTap: () -> Void
    let onEliminar: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ImagenAutenticada(url: mascota.urlImagen) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .frame(width: 56, height: 56)
            .background(Color.blue.opacity(0.1))
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(mascota.nombre)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(mascota.nombreEspecie)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            Button(action: onEliminar) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    MascotasView()
        .environmentObject(AuthService(mockData: true))
}
