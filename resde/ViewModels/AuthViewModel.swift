import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: AuthData?
    @Published var token: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let authService = AuthService(mockData: false)

    init() {
        authService.loadTokenFromKeychain()
        self.isAuthenticated = authService.isAuthenticated
        self.user = authService.user
        self.token = authService.token
    }

    func login(email: String, password: String) async {
        await authService.login(email: email, password: password)
        await MainActor.run {
            self.isAuthenticated = authService.isAuthenticated
            self.user = authService.user
            self.token = authService.token
            self.errorMessage = authService.errorMessage
            self.showError = !authService.isAuthenticated
            self.isLoading = authService.isLoading
        }
    }

    func logout() {
        authService.logout()
        self.isAuthenticated = false
        self.user = nil
        self.token = nil
    }
}
