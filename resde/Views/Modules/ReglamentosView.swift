import SwiftUI
import QuickLook

struct ReglamentosView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var reglamentos: [ReglamentoItem] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Reglamentos del Residencial")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("DOCUMENTOS DISPONIBLES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text("\(reglamentos.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else if showError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    } else if reglamentos.isEmpty {
                        Text("No hay documentos disponibles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(reglamentos) { item in
                                ReglamentoCard(item: item)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onAppear {
            Task { await loadReglamentos() }
        }
    }

    private func loadReglamentos() async {
        isLoading = true
        showError = false

        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/reglamentos") else {
            isLoading = false
            errorMessage = "URL inválida"
            showError = true
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard statusCode == 200 else {
                isLoading = false
                errorMessage = "No se pudieron cargar los reglamentos"
                showError = true
                return
            }

            let decoded = try JSONDecoder().decode(ReglamentosResponse.self, from: data)
            reglamentos = decoded.data ?? []
            isLoading = false
        } catch {
            print("❌ Error al cargar reglamentos: \(error)")
            isLoading = false
            errorMessage = "No se pudieron cargar los reglamentos"
            showError = true
        }
    }
}

// MARK: - Card

private struct ReglamentoCard: View {
    let item: ReglamentoItem
    @EnvironmentObject var authService: AuthService
    @State private var isDownloading = false
    @State private var previewURL: PreviewURL?
    @State private var errorMensaje: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(item.nombre)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.blue)
                Spacer()
                if item.es_general == true {
                    Text("General")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.4), lineWidth: 1))
                }
            }

            if let titulo = item.reglamento?.titulo {
                Text(titulo)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            if let errorMensaje = errorMensaje {
                Text(errorMensaje)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }

            HStack {
                Image(systemName: iconoTipoArchivo)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    if let tamano = item.reglamento?.tamano_formateado {
                        Text(tamano)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    if let fecha = item.reglamento?.fecha_actualizacion {
                        Text("Actualizado: \(fecha)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: { Task { await verODescargar() } }) {
                    HStack(spacing: 6) {
                        if isDownloading {
                            ProgressView()
                        } else {
                            Image(systemName: "eye.fill")
                        }
                        Text(isDownloading ? "Cargando..." : "Ver / Descargar")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.selectedTint)
                    .cornerRadius(16)
                }
                .disabled(isDownloading || item.tiene_archivo != true)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .sheet(item: $previewURL) { preview in
            VStack(spacing: 0) {
                HStack {
                    Text(item.reglamento?.archivo_nombre_original ?? item.nombre)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Button(action: { previewURL = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color(red: 0.05, green: 0.2, blue: 0.35))

                QuickLookPreview(url: preview.url)
            }
        }
    }

    private var iconoTipoArchivo: String {
        switch item.reglamento?.tipo_archivo?.lowercased() {
        case "pdf": return "doc.richtext.fill"
        default: return "doc.fill"
        }
    }

    private func verODescargar() async {
        errorMensaje = nil
        guard let urlString = item.reglamento?.url_archivo, let url = URL(string: urlString) else {
            errorMensaje = "Archivo no disponible"
            return
        }

        isDownloading = true

        var request = URLRequest(url: url)
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard statusCode == 200 else {
                isDownloading = false
                errorMensaje = "No se pudo descargar el archivo"
                return
            }

            let nombreArchivo = item.reglamento?.archivo_nombre_original ?? "\(item.slug).pdf"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(nombreArchivo)
            try data.write(to: tempURL, options: .atomic)

            isDownloading = false
            previewURL = PreviewURL(url: tempURL)
        } catch {
            print("❌ Error al descargar reglamento: \(error)")
            isDownloading = false
            errorMensaje = "No se pudo descargar el archivo"
        }
    }
}

private struct PreviewURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

// MARK: - Modelos

struct ReglamentoItem: Decodable, Identifiable {
    let id: Int
    let nombre: String
    let slug: String
    let es_general: Bool?
    let orden: Int?
    let tiene_archivo: Bool?
    let reglamento: ReglamentoArchivo?
}

struct ReglamentoArchivo: Decodable {
    let id: Int?
    let titulo: String?
    let archivo_nombre_original: String?
    let tipo_archivo: String?
    let tamano_bytes: Int?
    let tamano_formateado: String?
    let url_archivo: String?
    let fecha_actualizacion: String?
}

struct ReglamentosResponse: Decodable {
    let success: Bool?
    let total: Int?
    let residencial: String?
    let data: [ReglamentoItem]?
    let message: String?
}

#Preview {
    ReglamentosView()
        .environmentObject(AuthService(mockData: true))
}
