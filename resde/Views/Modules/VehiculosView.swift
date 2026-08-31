import SwiftUI

struct VehiculosView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").font(.system(size: 16)).foregroundColor(.blue)
                }
                Text("Vehículos").font(.system(size: 18, weight: .semibold)).foregroundColor(.primary)
                Spacer()
            }
            .padding(16).background(Color.white).shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
            ScrollView { VStack(alignment: .leading, spacing: 16) { Text("Módulo de Vehículos").font(.system(size: 20, weight: .bold)).padding(16); Spacer() } }
            Spacer()
        }
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
    }
}

#Preview { VehiculosView() }
