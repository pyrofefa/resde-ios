//
//  QuejasView.swift
//  resde
//

import SwiftUI
import PhotosUI
import UIKit

struct QuejasView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var selectedUbicacion = "Juan Rulfo #11"
    @State private var quejas: [Queja] = []
    @State private var isLoading = true
    @State private var showCreateQueja = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Quejas y sugerencias")
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
                                Text("Ubicación")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Text(selectedUbicacion)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                        if isLoading {
                            VStack(alignment: .center, spacing: 12) {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(24)
                        } else if quejas.isEmpty {
                            Text("No hay quejas registradas")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(quejas, id: \.id) { queja in
                                    QuejaCard(queja: queja)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color.appBackground)
            .navigationBarBackButtonHidden()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCreateQueja = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showCreateQueja) {
            CreateQuejaSheet(isPresented: $showCreateQueja, ubicacion: selectedUbicacion, onQuejaCreated: {
                loadQuejas()
            })
                .environmentObject(authService)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadQuejas()
        }
    }

    private func loadQuejas() {
        Task {
            isLoading = true
            if let ubicacionId = authService.user?.ubicaciones.first?.key {
                if let data = await fetchQuejas(ubicacionId: ubicacionId) {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📋 QUEJAS RESPONSE: \(jsonString)")
                    }
                    if let response = try? JSONDecoder().decode(QuejasListResponse.self, from: data) {
                        await MainActor.run {
                            self.quejas = response.data ?? []
                        }
                    }
                }
            }
            isLoading = false
        }
    }

    private func fetchQuejas(ubicacionId: String) async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/quejas?ubicacion_id=\(ubicacionId)") else {
            return nil
        }

        var request = URLRequest(url: url)
        print("🌐 Quejas URL: \(url.absoluteString)")
        print("🔑 Token: \(authService.token ?? "NIL")")

        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ Authorization header set")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 Status code: \(httpResponse.statusCode)")
            }
            return data
        } catch {
            print("❌ Error fetching quejas: \(error)")
            return nil
        }
    }
}

struct QuejaCard: View {
    let queja: Queja

    var statusColor: Color {
        switch queja.estatus?.id {
        case 1: return Color(red: 0.2, green: 0.7, blue: 0.2)
        case 2: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case 3: return Color(red: 0.5, green: 0.5, blue: 0.5)
        default: return Color.gray
        }
    }

    var statusText: String {
        queja.estatus?.descripcion ?? "Desconocido"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(queja.tipo?.descripcion ?? "Queja")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(queja.ubicacion_id > 0 ? "Juan Rulfo #11" : "")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(statusColor)
                    .cornerRadius(12)
            }
            Text(queja.descripcion ?? "")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct Queja: Codable, Identifiable {
    let id: Int
    let fecha: String?
    let folio: String?
    let descripcion: String?
    let ubicacion_id: Int
    let tipo: TipoQueja?
    let estatus: EstatusQueja?
}

struct TipoQueja: Codable {
    let id: Int?
    let descripcion: String?
}

struct EstatusQueja: Codable {
    let id: Int?
    let descripcion: String?
}

struct QuejasListResponse: Codable {
    let success: Bool?
    let total: Int?
    let message: String?
    let data: [Queja]?
}

struct CreateQuejaSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @Binding var isPresented: Bool
    @State private var tiposQuejas: [TipoQueja] = []
    @State private var selectedTipo: TipoQueja?
    @State private var descripcion = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    let ubicacion: String
    let onQuejaCreated: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Registro de queja")
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
            .borderBottom()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ubicación")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)

                            Text(ubicacion)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tipo de queja")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Menu {
                            ForEach(tiposQuejas, id: \.id) { tipo in
                                Button(action: {
                                    selectedTipo = tipo
                                }) {
                                    Text(tipo.descripcion ?? "")
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedTipo?.descripcion ?? "Seleccione un tipo de queja")
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedTipo == nil ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 2))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        TextEditor(text: $descripcion)
                            .font(.system(size: 16))
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    }

                    if let image = selectedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Foto de evidencia")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    selectedImage = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .cornerRadius(12)
                                .clipped()
                        }
                    } else {
                        VStack(alignment: .center, spacing: 12) {
                            HStack(spacing: 20) {
                                Button(action: {
                                    showCamera = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                                PhotosPicker(selection: $photoItem, matching: .images) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }
                            Image(systemName: "arrow.up")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.gray)
                            Text("Subir una foto de evidencia")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5])))
                    }

                    Button(action: {
                        isSubmitting = true
                        Task {
                            await createQueja()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                            Text("Registrar Queja")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting || selectedTipo == nil || descripcion.isEmpty)
                }
                .padding(16)
            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .onChange(of: photoItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data)
                }
            }
        }
        .onAppear {
            loadTiposQuejas()
        }
    }

    private func loadTiposQuejas() {
        Task {
            isLoading = true
            if let data = await fetchTiposQuejas() {
                if let response = try? JSONDecoder().decode(TiposQuejasResponse.self, from: data) {
                    await MainActor.run {
                        self.tiposQuejas = response.data ?? []
                    }
                }
            }
            isLoading = false
        }
    }

    private func fetchTiposQuejas() async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/quejas/tipos") else {
            return nil
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            return data
        } catch {
            print("❌ Error fetching tipos: \(error)")
            return nil
        }
    }

    private func createQueja() async {
        guard let ubicacionId = authService.user?.ubicaciones.first?.key,
              let tipoId = selectedTipo?.id,
              let userId = authService.user?.id else {
            isSubmitting = false
            return
        }

        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let fechaStr = formatter.string(from: today)

        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/quejas") else {
            isSubmitting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authService.token ?? "")", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "fecha": fechaStr,
            "user_id": String(userId),
            "residencial_id": String(authService.user?.residencial_id ?? 1),
            "ubicacion_id": ubicacionId,
            "tipo_queja_id": String(tipoId),
            "estatus_queja_id": "1",
            "descripcion": descripcion
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) ?? Data())
            body.append("\(value)\r\n".data(using: .utf8) ?? Data())
        }

        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
            body.append("Content-Disposition: form-data; name=\"imagen\"; filename=\"queja.jpg\"\r\n".data(using: .utf8) ?? Data())
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8) ?? Data())
            body.append(imageData)
            body.append("\r\n".data(using: .utf8) ?? Data())
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())

        request.httpBody = body

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                await MainActor.run {
                    isSubmitting = false
                    onQuejaCreated()
                    dismiss()
                }
            }
        } catch {
            print("❌ Error creating queja: \(error)")
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
}

struct TiposQuejasResponse: Codable {
    let success: Bool?
    let data: [TipoQueja]?
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            return picker
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = context.coordinator
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

extension View {
    func borderBottom() -> some View {
        self.overlay(
            VStack {
                Spacer()
                Divider()
            }
        )
    }
}

#Preview { QuejasView().environmentObject(AuthService(mockData: true)) }
