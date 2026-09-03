import SwiftUI

struct ChangePasswordSheet: View {
    @Binding var isPresented: Bool
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Actualizar Contraseña")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Define una nueva clave de acceso para esta cuenta vinculada.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nueva contraseña")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            HStack {
                                if showPassword {
                                    TextField("Nueva contraseña", text: $newPassword)
                                        .font(.system(size: 16))
                                } else {
                                    SecureField("Nueva contraseña", text: $newPassword)
                                        .font(.system(size: 16))
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(12)
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Confirmar contraseña")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            HStack {
                                if showPassword {
                                    TextField("Confirmar contraseña", text: $confirmPassword)
                                        .font(.system(size: 16))
                                } else {
                                    SecureField("Confirmar contraseña", text: $confirmPassword)
                                        .font(.system(size: 16))
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(12)
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }

                        Text("Mínimo 8 caracteres.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.square.fill")
                            Text("Actualizar Contraseña")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                        .cornerRadius(12)
                    }

                    Button(action: { isPresented = false }) {
                        Text("Cancelar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
        }
    }
}
