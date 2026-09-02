import SwiftUI

struct CuentaDetailSheet: View {
    let cuenta: Cuenta
    @Environment(\.dismiss) var dismiss
    @State private var showChangePassword = false
    @State private var showEditAccount = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cuenta.nombre_completo)
                                .font(.system(size: 18, weight: .semibold))
                            Text(cuenta.email)
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Teléfono")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(cuenta.telefono ?? "N/A")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Estado")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(cuenta.status == 1 ? "Activo" : "Inactivo")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("¿Renta?")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(cuenta.renta_texto)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: { showEditAccount = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                    Text("Editar")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.blueTint)
                                .cornerRadius(12)
                            }

                            Button(action: { showChangePassword = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock")
                                    Text("Contraseña")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(red: 0.0, green: 0.4, blue: 0.7))
                                .cornerRadius(12)
                            }
                        }

                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text("Desactivar cuenta")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.redTint)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Detalle de Cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet(isPresented: $showChangePassword)
                    .presentationDetents([.fraction(0.6)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showEditAccount) {
                EditarCuentaSheet(cuenta: cuenta, isPresented: $showEditAccount)
            }
        }
    }
}
