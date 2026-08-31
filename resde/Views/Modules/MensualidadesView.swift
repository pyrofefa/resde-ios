//
//  MensualidadesView.swift
//  resde
//

import SwiftUI

struct MensualidadesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedUbicacion = "Juan Rulfo #11"

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeader(title: "Estado de Deuda")

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

                    VStack(spacing: 8) {
                        Text("DEUDA TOTAL ACUMULADA")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                        Text("$3,000.00")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(Color(red: 1, green: 0.95, blue: 0.95))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                    ForEach([2026, 2025, 2020], id: \.self) { year in
                        YearDebtCard(year: year)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
    }
}

struct YearDebtCard: View {
    let year: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(year)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Adeudo de este año")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Pagado: $0.00")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.2))
                    HStack(spacing: 4) {
                        Text("$1,200.00")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    Text("Ver detalle")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    MensualidadesView()
}
