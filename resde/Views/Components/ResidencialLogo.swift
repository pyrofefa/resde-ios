//
//  ResidencialLogo.swift
//  resde
//

import SwiftUI
import UIKit

/// Muestra el logo de la residencial (base64 que devuelve el login / `/me`).
/// Si el valor falta o no se puede decodificar, usa el logo de la app.
struct ResidencialLogo: View {
    let base64: String?
    var size: CGFloat = 50

    private static let cache = NSCache<NSString, UIImage>()

    private var imagen: UIImage? {
        guard let base64, !base64.isEmpty else { return nil }
        let clave = base64 as NSString
        if let cached = Self.cache.object(forKey: clave) { return cached }

        // Acepta tanto "data:image/png;base64,XXXX" como el base64 a secas.
        let limpio = base64.contains(",") ? String(base64.split(separator: ",", maxSplits: 1).last ?? "") : base64
        guard let data = Data(base64Encoded: limpio, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else { return nil }

        Self.cache.setObject(image, forKey: clave)
        return image
    }

    var body: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("logoApp")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
    }
}

/// Indicador de carga de una sección: logo de la residencial con un anillo de progreso.
struct SeccionCargando: View {
    let logo: String?
    var height: CGFloat = 120

    var body: some View {
        ZStack {
            AnilloCargando(size: 72, grosor: 5)

            ResidencialLogo(base64: logo, size: 44)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}
