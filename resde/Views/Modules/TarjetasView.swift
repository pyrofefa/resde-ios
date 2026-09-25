//
//  TarjetasView.swift
//  resde
//

import SwiftUI
import UIKit

struct TarjetasView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var selectedUbicacion = ""
    @State private var tarjetas: [Tarjeta] = []
    @State private var isLoading = true
    @State private var selectedTarjeta: Tarjeta?
    @State private var showDeactivateSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Tarjetas de acceso")
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

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("TARJETAS REGISTRADAS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(String(tarjetas.count))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(minWidth: 24)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }

                        if isLoading {
                            VStack(alignment: .center, spacing: 12) {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(24)
                        } else if tarjetas.isEmpty {
                            Text("No hay tarjetas registradas")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(tarjetas, id: \.id) { tarjeta in
                                    Button(action: {
                                        selectedTarjeta = tarjeta
                                        showDeactivateSheet = true
                                    }) {
                                        TarjetaCard(tarjeta: tarjeta)
                                    }
                                    .disabled(tarjeta.status != 1)
                                    .opacity(tarjeta.status == 1 ? 1.0 : 0.6)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
                .padding(16)
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .sheet(item: $selectedTarjeta) { tarjeta in
            DeactivateTarjetaSheet(tarjeta: tarjeta, isPresented: $showDeactivateSheet)
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if selectedUbicacion.isEmpty {
                selectedUbicacion = authService.user?.ubicaciones.first?.value ?? ""
            }
            loadTarjetas()
        }
    }

    private func loadTarjetas() {
        Task {
            isLoading = true
            if let ubicacionId = authService.user?.ubicaciones.first?.key {
                if let data = await fetchTarjetas(ubicacionId: ubicacionId) {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📋 TARJETAS RESPONSE: \(jsonString)")
                    }
                    if let response = try? JSONDecoder().decode(TarjetasGetResponse.self, from: data) {
                        await MainActor.run {
                            self.tarjetas = response.cards ?? []
                        }
                    }
                }
            }
            isLoading = false
        }
    }

    private func fetchTarjetas(ubicacionId: String) async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/tarjetas/get?ubicacion_id=\(ubicacionId)") else {
            return nil
        }

        var request = URLRequest(url: url)
        print("🌐 Tarjetas URL: \(url.absoluteString)")
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
            print("❌ Error fetching tarjetas: \(error)")
            return nil
        }
    }
}

struct TarjetaCard: View {
    let tarjeta: Tarjeta

    var statusColor: Color {
        tarjeta.status == 1 ? Color.statusSuccess : Color.statusError
    }

    var statusText: String {
        tarjeta.status == 1 ? "Activa" : "DESACTIVADA"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "wifi.router.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 50, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(tarjeta.numero_tarjeta ?? "N/A")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct DeactivateTarjetaSheet: View {
    @Environment(\.dismiss) var dismiss
    let tarjeta: Tarjeta
    @Binding var isPresented: Bool
    @State private var isDeactivating = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)

                Text("Dar de baja tarjeta")
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    Image(systemName: "wifi.router.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 45, height: 45)
                        .background(Color.red)
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Número de tarjeta")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(tarjeta.numero_tarjeta ?? "N/A")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 16)

                Text("Al dar de baja esta tarjeta, se desactivará de forma permanente el acceso a la unidad. Esta acción no se puede deshacer.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    Button(action: {
                        isDeactivating = true
                        Task {
                            await deactivateTarjeta()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                            Text("Dar de baja tarjeta")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    .disabled(isDeactivating)

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancelar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blueTint)
                            .cornerRadius(8)
                    }
                    .disabled(isDeactivating)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)

            Spacer()
        }
        .background(Color.cardBackground)
    }

    private func deactivateTarjeta() async {
        // Placeholder for API call to deactivate tarjeta
        print("Deactivating tarjeta: \(tarjeta.numero_tarjeta ?? "N/A")")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isPresented = false
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct Tarjeta: Codable, Identifiable {
    let id: Int?
    let numero_tarjeta: String?
    let status: Int?
}

struct TarjetasGetResponse: Codable {
    let success: Bool?
    let cards: [Tarjeta]?
    let message: String?
}

#Preview {
    TarjetasView()
        .environmentObject(AuthService(mockData: true))
}
