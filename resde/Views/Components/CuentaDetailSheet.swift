import SwiftUI

struct CuentaDetailSheet: View {
    let cuenta: Cuenta
    @ObservedObject var viewModel: CuentasViewModel
    /// Se llama tras editar, cambiar contraseña o cambiar el estatus, con el mensaje del servidor.
    let onActualizado: (String) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var showChangePassword = false
    @State private var showEditAccount = false
    @State private var confirmarEstatus = false
    @State private var isToggling = false
    @State private var errorAlert: ErrorPeticionMensaje?

    private var esActiva: Bool { cuenta.status == 1 }

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
                            dato("Teléfono", cuenta.telefono ?? "N/A")
                            Spacer()
                            dato("Estado", esActiva ? "Activo" : "Inactivo")
                        }
                        HStack {
                            dato("¿Renta?", cuenta.renta_texto)
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
                                .background(Color.accionPrimaria)
                                .cornerRadius(12)
                            }
                        }

                        Button(action: { confirmarEstatus = true }) {
                            HStack(spacing: 8) {
                                if isToggling {
                                    ProgressView()
                                } else {
                                    Image(systemName: esActiva ? "trash" : "plus.circle")
                                }
                                Text(esActiva ? "Desactivar cuenta" : "Activar cuenta")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(esActiva ? .red : Color.statusSuccess)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(esActiva ? Color.redTint : Color.statusSuccess.opacity(0.12))
                            .cornerRadius(12)
                        }
                        .disabled(isToggling)
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
                ChangePasswordSheet(
                    cuenta: cuenta,
                    viewModel: viewModel,
                    isPresented: $showChangePassword,
                    onActualizada: { mensaje in
                        dismiss()
                        onActualizado(mensaje)
                    }
                )
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showEditAccount) {
                EditarCuentaSheet(
                    cuenta: cuenta,
                    viewModel: viewModel,
                    isPresented: $showEditAccount,
                    onGuardado: { mensaje in
                        dismiss()
                        onActualizado(mensaje)
                    }
                )
            }
            .sheet(item: $errorAlert) { error in
                ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: { errorAlert = nil })
                    .presentationDetents([.fraction(0.45)])
            }
            .alert(esActiva ? "Desactivar cuenta" : "Activar cuenta", isPresented: $confirmarEstatus) {
                Button("Cancelar", role: .cancel) {}
                Button(esActiva ? "Sí, desactivar" : "Sí, activar", role: esActiva ? .destructive : nil) {
                    Task { await cambiarEstatus() }
                }
            } message: {
                Text("¿Estás seguro que deseas \(esActiva ? "desactivar" : "activar") la cuenta de \(cuenta.nombre_completo)?")
            }
        }
    }

    private func dato(_ titulo: String, _ valor: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Text(valor)
                .font(.system(size: 16, weight: .semibold))
        }
    }

    private func cambiarEstatus() async {
        isToggling = true
        let resultado = await viewModel.cambiarEstatus(id: cuenta.id)
        isToggling = false

        if resultado.exito {
            dismiss()
            onActualizado(resultado.mensaje)
        } else {
            errorAlert = ErrorPeticionMensaje(mensaje: resultado.mensaje)
        }
    }
}
