import SwiftUI

extension Color {
    static let appBackgroundLight = Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1)
    static let appBackgroundDark = Color(red: 0, green: 0, blue: 0)

    static let cardBackgroundLight = Color.white
    static let cardBackgroundDark = Color(red: 0.06, green: 0.06, blue: 0.06)

    static let headerBackground = Color(red: 0.05, green: 0.2, blue: 0.35)

    /// Fondo general de las pantallas. Gris claro en modo claro, negro/gris muy oscuro en modo oscuro.
    static let appBackground = Color(UIColor.systemGroupedBackground)

    /// Fondo de tarjetas y contenedores. Blanco en modo claro, gris oscuro en modo oscuro.
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)

    /// Fondo de campos de texto/inputs dentro de tarjetas.
    static let fieldBackground = Color(UIColor.tertiarySystemGroupedBackground)

    /// Tinte lavanda usado para pills/botones seleccionados. Claro en modo claro, morado apagado en modo oscuro.
    static let selectedTint = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.32, green: 0.24, blue: 0.46, alpha: 1.0)
            : UIColor(red: 0.9, green: 0.85, blue: 1.0, alpha: 1.0)
    })

    /// Tinte azul claro para botones/acentos secundarios. Se oscurece en modo oscuro.
    static let blueTint = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.22, blue: 0.34, alpha: 1.0)
            : UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
    })

    /// Tinte rojo claro para botones/acentos destructivos. Se oscurece en modo oscuro.
    static let redTint = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.36, green: 0.16, blue: 0.16, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0)
    })

    /// Tinte verde claro para tarjetas de confirmación/éxito. Se oscurece en modo oscuro.
    static let greenTint = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.26, blue: 0.18, alpha: 1.0)
            : UIColor(red: 0.88, green: 0.96, blue: 0.9, alpha: 1.0)
    })

    /// Verde sólido para estados positivos (pagado, válido, éxito, activo).
    static let statusSuccess = Color(red: 0.2, green: 0.7, blue: 0.2)

    /// Rojo sólido para estados negativos (vencido, fallido, error, inactivo).
    static let statusError = Color(red: 0.8, green: 0.2, blue: 0.2)

    /// Naranja sólido para estados intermedios (pendiente, iniciada, parcial).
    static let statusWarning = Color(red: 0.9, green: 0.6, blue: 0.0)

    /// Verde de marca de WhatsApp, usado para el enlace/indicador del bot RESDE Guard.
    static let whatsappGreen = Color(red: 0.15, green: 0.7, blue: 0.35)
}

struct AppBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content.background(
            colorScheme == .dark ? Color.appBackgroundDark : Color.appBackgroundLight
        )
    }
}

struct CardBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content.background(
            colorScheme == .dark ? Color.cardBackgroundDark : Color.cardBackgroundLight
        )
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }

    func cardBackground() -> some View {
        modifier(CardBackgroundModifier())
    }
}
