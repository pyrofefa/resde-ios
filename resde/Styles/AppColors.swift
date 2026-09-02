import SwiftUI

extension Color {
    static let appBackgroundLight = Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1)
    static let appBackgroundDark = Color(red: 0, green: 0, blue: 0)

    static let cardBackgroundLight = Color.white
    static let cardBackgroundDark = Color(red: 0.06, green: 0.06, blue: 0.06)

    static let headerBackground = Color(red: 0.05, green: 0.2, blue: 0.35)
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
