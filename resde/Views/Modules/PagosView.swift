//
//  PagosView.swift
//  resde
//

import SwiftUI

struct PagosView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var selectedUbicacion = "Todas las ubicaciones"
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeader(title: "Pagos")

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
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 40) {
                            Text("FOLIO")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("FECHA")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("UBICACIÓN")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer()
                            .frame(height: 100)

                        VStack(spacing: 16) {
                            Text("No se encontraron pagos para este periodo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(40)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(16)
            }
        }
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
        .onAppear {
            loadPagosData()
        }
    }

    private func loadPagosData() {
        Task {
            isLoading = true
            let currentYear = Calendar.current.component(.year, from: Date())
            let params = ["ano": String(currentYear)]
            if let data = await authService.fetchCarouselData(endpoint: "pagos/anual", params: params) {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Pagos Data: \(jsonString)")
                }
            } else {
                print("❌ No data received from pagos/anual")
            }
            isLoading = false
        }
    }
}

#Preview {
    PagosView()
}
