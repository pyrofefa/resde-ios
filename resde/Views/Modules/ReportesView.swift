//
//  ReportesView.swift
//  resde
//

import SwiftUI

struct ReportesView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ModuleHeader(title: "Reportes")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Módulo de Reportes")
                        .font(.system(size: 20, weight: .bold))
                        .padding(16)
                    Spacer()
                }
            }
            Spacer()
        }
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    ReportesView()
}
