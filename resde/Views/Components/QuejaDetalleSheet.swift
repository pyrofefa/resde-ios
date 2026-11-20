import SwiftUI
import UIKit

/// Detalle de una queja (igual al de Android): ubicación, tipo, descripción, estatus,
/// fecha de cierre (si ya se cerró) e imagen adjunta.
struct QuejaDetalleSheet: View {
    let queja: Queja
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var imagen: UIImage?
    @State private var cargandoImagen = false
    @State private var falloImagen = false
    @State private var verImagenCompleta = false

    private var ubicacionTexto: String {
        authService.user?.ubicaciones[String(queja.ubicacion_id)] ?? "—"
    }

    private var statusColor: Color {
        switch queja.estatus?.id {
        case 1: return Color.statusSuccess
        case 2: return Color.statusWarning
        case 3: return Color(red: 0.5, green: 0.5, blue: 0.5)
        default: return Color.gray
        }
    }

    private var rutaImagen: String? {
        guard let ruta = queja.url_imagen_public, !ruta.isEmpty else { return nil }
        return ruta
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        campo("Ubicación", ubicacionTexto)
                        campo("Tipo de queja", queja.tipo?.descripcion ?? "—")
                        campo("Descripción", (queja.descripcion?.isEmpty == false) ? queja.descripcion! : "Sin descripción")

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                etiqueta("Estatus")
                                Text((queja.estatus?.descripcion ?? "Desconocido").uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(statusColor)
                                    .cornerRadius(12)
                            }
                            Spacer()
                            if let cierre = queja.fecha_cierre, !cierre.isEmpty {
                                campo("Fecha de cierre", cierre)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                    if rutaImagen != nil {
                        imagenAdjunta
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Detalle de la Queja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.gray)
                    }
                }
            }
        }
        .task { await cargarImagen() }
        .fullScreenCover(isPresented: $verImagenCompleta) {
            ZStack {
                Color.black.ignoresSafeArea()
                if let imagen {
                    Image(uiImage: imagen)
                        .resizable()
                        .scaledToFit()
                }
            }
            .onTapGesture { verImagenCompleta = false }
            .overlay(alignment: .topTrailing) {
                Button(action: { verImagenCompleta = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(16)
                }
            }
        }
    }

    // MARK: - Imagen

    @ViewBuilder
    private var imagenAdjunta: some View {
        VStack(alignment: .leading, spacing: 8) {
            etiqueta("Imagen adjunta")

            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .onTapGesture { verImagenCompleta = true }
                Text("Toca la imagen para verla completa")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else if falloImagen {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                    Text("No se pudo cargar la imagen")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.cardBackground)
                .cornerRadius(12)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(24)
            }
        }
    }

    /// La imagen requiere el token de sesión, por eso no se usa AsyncImage.
    private func cargarImagen() async {
        guard let ruta = rutaImagen, imagen == nil, !cargandoImagen else { return }
        cargandoImagen = true
        defer { cargandoImagen = false }

        let urlString = ruta.hasPrefix("http") ? ruta : "https://resde.aseenti.com.mx" + ruta
        guard let url = URL(string: urlString) else { falloImagen = true; return }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            if let image = UIImage(data: data) {
                imagen = image
            } else {
                falloImagen = true
            }
        } catch {
            print("❌ Error al cargar imagen de queja: \(error)")
            falloImagen = true
        }
    }

    // MARK: - Helpers

    private func etiqueta(_ texto: String) -> some View {
        Text(texto)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
    }

    private func campo(_ titulo: String, _ valor: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            etiqueta(titulo)
            Text(valor)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}
