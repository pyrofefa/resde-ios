//
//  CargandoDialog.swift
//  resde
//

import SwiftUI

/// Anillo de progreso indeterminado como el `CircularProgressIndicator` de Material en Android:
/// un arco redondeado que gira y cambia de largo, sin pista de fondo.
struct AnilloCargando: View {
    var size: CGFloat = 88
    var grosor: CGFloat = 6
    var color: Color = Color(red: 0.0, green: 0.4, blue: 0.7)

    @State private var rotacion: Double = 0
    @State private var largo: CGFloat = 0.1

    var body: some View {
        Circle()
            .inset(by: grosor / 2)
            .trim(from: 0, to: largo)
            .stroke(color, style: StrokeStyle(lineWidth: grosor, lineCap: .round))
            .rotationEffect(.degrees(rotacion - 90))
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    rotacion = 360
                }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    largo = 0.75
                }
            }
    }
}

/// Diálogo modal de "cargando" (igual al de Android): logo con anillo de progreso,
/// título y mensaje. Bloquea la interacción con lo que hay detrás.
struct CargandoDialog: View {
    let titulo: String
    let mensaje: String
    var logo: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    AnilloCargando(size: 88, grosor: 6)

                    ResidencialLogo(base64: logo, size: 56)
                }
                .frame(width: 96, height: 96)

                VStack(spacing: 4) {
                    Text(titulo)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text(mensaje)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(minWidth: 240, maxWidth: 280)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .transition(.opacity)
    }
}

extension View {
    /// Muestra el diálogo de carga encima de la vista mientras `isPresented` sea true.
    func cargandoDialog(
        isPresented: Bool,
        titulo: String,
        mensaje: String,
        logo: String? = nil
    ) -> some View {
        overlay {
            if isPresented {
                CargandoDialog(titulo: titulo, mensaje: mensaje, logo: logo)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}
