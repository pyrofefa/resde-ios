import SwiftUI
import PhotosUI

/// Alta y edición de mascota (equivale a MascotaFormActivity en Android).
struct MascotaFormSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @ObservedObject var viewModel: MascotasViewModel

    let mascota: Mascota?
    let onGuardada: (String) -> Void

    @State private var nombre = ""
    @State private var especieId: Int?
    @State private var fotoNueva: UIImage?
    @State private var eliminarFoto = false
    @State private var mostrarCamara = false
    @State private var photoItem: PhotosPickerItem?
    @State private var error: ErrorPeticionMensaje?

    private var esEdicion: Bool { mascota != nil }
    private var tieneFotoActual: Bool { mascota?.urlImagen != nil }
    private var mostrarFotoActual: Bool { fotoNueva == nil && tieneFotoActual && !eliminarFoto }
    private var hayFoto: Bool { fotoNueva != nil || mostrarFotoActual }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(esEdicion ? "Editar Mascota" : "Registrar Mascota")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color.cardBackground)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ubicacionCard

                    campo("Nombre de la mascota") {
                        TextField("Nombre", text: $nombre)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 15))
                    }

                    campo("Especie") {
                        Menu {
                            ForEach(viewModel.especies) { especie in
                                Button(especie.descripcion) { especieId = especie.id }
                            }
                        } label: {
                            HStack {
                                Text(nombreEspecieSeleccionada)
                                    .font(.system(size: 15))
                                    .foregroundColor(especieId == nil ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    fotoSeccion

                    Button(action: { Task { await guardar() } }) {
                        HStack(spacing: 8) {
                            if viewModel.isWorking {
                                ProgressView().tint(.white)
                            }
                            Text(viewModel.isWorking ? "Guardando..." : (esEdicion ? "Guardar cambios" : "Registrar mascota"))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                        .cornerRadius(25)
                    }
                    .disabled(viewModel.isWorking)
                }
                .padding(16)
            }
        }
        .background(Color.appBackground)
        .task {
            await viewModel.cargarEspecies()
            if let mascota, especieId == nil,
               viewModel.especies.contains(where: { $0.id == mascota.especieId }) {
                especieId = mascota.especieId
            }
        }
        .onAppear {
            if let mascota, nombre.isEmpty { nombre = mascota.nombre }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let datos = try? await item.loadTransferable(type: Data.self),
                   let imagen = UIImage(data: datos) {
                    seleccionar(imagen)
                }
                photoItem = nil
            }
        }
        .onChange(of: fotoNueva) { _, nueva in
            if nueva != nil { eliminarFoto = false }
        }
        .fullScreenCover(isPresented: $mostrarCamara) {
            CameraView(image: Binding(
                get: { fotoNueva },
                set: { if let imagen = $0 { seleccionar(imagen) } }
            ))
            .ignoresSafeArea()
        }
        .sheet(item: $error) { e in
            ErrorPeticionDialog(mensaje: e.mensaje, onCerrar: { error = nil })
                .presentationDetents([.fraction(0.45)])
        }
    }

    // MARK: - Partes

    private var nombreEspecieSeleccionada: String {
        if let id = especieId, let especie = viewModel.especies.first(where: { $0.id == id }) {
            return especie.descripcion
        }
        return "Selecciona una especie"
    }

    private var ubicacionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 18))
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ubicación")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(authService.ubicacionActualNombre ?? "N/A")
                    .font(.system(size: 15, weight: .semibold))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    private func campo<Contenido: View>(_ titulo: String, @ViewBuilder contenido: () -> Contenido) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            contenido()
                .padding(12)
                .background(Color.fieldBackground)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        }
    }

    private var fotoSeccion: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fotografía (opcional)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            ZStack {
                if let fotoNueva {
                    Image(uiImage: fotoNueva)
                        .resizable()
                        .scaledToFill()
                } else if mostrarFotoActual {
                    ImagenAutenticada(url: mascota?.urlImagen) { huella }
                } else {
                    huella
                }
            }
            .frame(width: 140, height: 140)
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Button(action: { mostrarCamara = true }) {
                    etiquetaAccion("camera.fill", "Cámara")
                }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    etiquetaAccion("photo.fill", "Galería")
                }
            }

            if hayFoto {
                Button(action: quitarFoto) {
                    Text("Quitar foto")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                }
            }

            if esEdicion && tieneFotoActual {
                Toggle("Eliminar foto actual", isOn: $eliminarFoto)
                    .font(.system(size: 14))
                    .onChange(of: eliminarFoto) { _, activo in
                        if activo { fotoNueva = nil }
                    }
            }
        }
    }

    private var huella: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: 48))
            .foregroundColor(.blue)
    }

    private func etiquetaAccion(_ icono: String, _ texto: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icono)
            Text(texto)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.blue)
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Acciones

    private func seleccionar(_ imagen: UIImage) {
        fotoNueva = imagen
        eliminarFoto = false
    }

    private func quitarFoto() {
        fotoNueva = nil
        if tieneFotoActual { eliminarFoto = true }
    }

    private func guardar() async {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else {
            error = ErrorPeticionMensaje(mensaje: "Ingrese el nombre de la mascota")
            return
        }
        guard let especieId else {
            error = ErrorPeticionMensaje(mensaje: "Seleccione una especie válida")
            return
        }
        guard let ubicacionId = authService.ubicacionActualId else {
            error = ErrorPeticionMensaje(mensaje: "No se pudo determinar la ubicación")
            return
        }

        let resultado = await viewModel.guardar(
            mascota: mascota,
            ubicacionId: ubicacionId,
            nombre: limpio,
            especieId: especieId,
            foto: fotoNueva,
            eliminarFoto: eliminarFoto
        )

        if resultado.exito {
            onGuardada(resultado.mensaje)
            dismiss()
        } else {
            error = ErrorPeticionMensaje(mensaje: resultado.mensaje)
        }
    }
}
