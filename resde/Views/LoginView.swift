//
//  LoginView.swift
//  resde
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        loginContent
    }

    private var loginContent: some View {
        VStack(spacing: 0) {
            // HEADER / LOGO
            Image("logoApp")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            VStack(spacing: 4) {
                Text("Bienvenido a Resde")
                    .font(.system(size: 22, weight: .semibold))

                Text("Inicia sesión para gestionar tu residencial")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // ERROR MESSAGE
            if let errorMessage = authService.errorMessage {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            // FORM
            VStack(spacing: 16) {
                // Email Field
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)

                    TextField("Email", text: $email)
                        .disabled(authService.isLoading)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 24)

                // Password Field
                HStack(spacing: 12) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)

                    if showPassword {
                        TextField("Contraseña", text: $password)
                            .disabled(authService.isLoading)
                    } else {
                        SecureField("Contraseña", text: $password)
                            .disabled(authService.isLoading)
                    }

                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .disabled(authService.isLoading)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
            .padding(.top, 40)

            // Login Button
            Button(action: { handleLogin() }) {
                if authService.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Ingresar")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(12)
            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
            .opacity(authService.isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()

            // BRANDING / FOOTER
            VStack(spacing: 8) {
                Text("Desarrollado por")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Image("AseentiIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)

                Text("Versión \(version)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .padding(.vertical, 40)
    }

    private func handleLogin() {
        Task {
            await authService.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService(mockData: false))
}
