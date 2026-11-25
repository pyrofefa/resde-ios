import SwiftUI

/// Carga una imagen protegida con el token Bearer (equivalente a Glide + LazyHeaders en Android).
/// Mientras carga, o si falla, muestra `placeholder`.
struct ImagenAutenticada<Placeholder: View>: View {
    let url: URL?
    let placeholder: Placeholder

    @EnvironmentObject private var authService: AuthService
    @State private var imagen: UIImage?

    init(url: URL?, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .task(id: url) { await cargar() }
    }

    private func cargar() async {
        guard let url else {
            imagen = nil
            return
        }
        if let cacheada = ImagenAutenticadaCache.shared.object(forKey: url as NSURL) {
            imagen = cacheada
            return
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let descargada = UIImage(data: data) else {
            imagen = nil
            return
        }
        ImagenAutenticadaCache.shared.setObject(descargada, forKey: url as NSURL)
        imagen = descargada
    }
}

enum ImagenAutenticadaCache {
    static let shared: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 100
        return cache
    }()
}
