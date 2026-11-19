//
//  CargandoDialog.swift
//  resde
//

import SwiftUI

/// Diálogo modal de "cargando" (igual al de Android): logo con anillo de progreso,
/// título y mensaje. Bloquea la interacción con lo que hay detrás.
struct CargandoDialog: View {
    let titulo: String
    let mensaje: String
    var logo: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(2.6)
                        .tint(.blue)

                    ResidencialLogo(base64: logo, size: 44)
                }
                .frame(width: 88, height: 88)

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
            .frame(maxWidth: 280)
            .background(Color.cardBackground)
            .cornerRadius(16)
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
