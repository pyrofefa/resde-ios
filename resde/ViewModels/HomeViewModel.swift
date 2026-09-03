import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var carouselData: [CarouselItem] = []
    @Published var errorMessage: String?
    @Published var showError = false

    private let authService = AuthService(mockData: false)

    func loadData(ubicacionId: String) async {
        isLoading = true
        errorMessage = nil
        showError = false

        // Aquí cargas los datos del carousel en paralelo
        // Este es un ejemplo - ajusta según tus endpoints reales
        do {
            let items = await loadCarouselItems(ubicacionId: ubicacionId)
            await MainActor.run {
                self.carouselData = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error al cargar datos"
                self.showError = true
                self.isLoading = false
            }
        }
    }

    private func loadCarouselItems(ubicacionId: String) async -> [CarouselItem] {
        // Implementar carga de datos del carousel
        return []
    }
}
