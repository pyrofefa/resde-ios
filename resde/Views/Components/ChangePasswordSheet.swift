import SwiftUI

struct ChangePasswordSheet: View {
    let cuenta: Cuenta
    @ObservedObject var viewModel: CuentasViewModel
    @Binding var isPresented: Bool
    let onActualizada: (String) -> Void

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isSaving = false
    @State private var errorAlert: ErrorPeticionMensaje?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Actualizar Contraseña")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Define una nueva clave de acceso para \(cuenta.nombre_completo).")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    CampoContrasena(titulo: "Nueva contraseña", texto: $newPassword, mostrar: $showPassword)
                    CampoContrasena(titulo: "Confirmar contraseña", texto: $confirmPassword, mostrar: $showPassword)

                    Text("Mínimo 8 caracteres.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    BotonAccion(titulo: isSaving ? "Actualizando..." : "Actualizar Contraseña", cargando: isSaving) {
                        Task { await actualizar() }
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
        .sheet(item: $errorAlert) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: { errorAlert = nil })
                .presentationDetents([.fraction(0.45)])
        }
    }

    private func actualizar() async {
        if newPassword.count < 8 {
            errorAlert = ErrorPeticionMensaje(mensaje: "La contraseña debe tener al menos 8 caracteres")
            return
        }
        if newPassword != confirmPassword {
            errorAlert = ErrorPeticionMensaje(mensaje: "Las contraseñas no coinciden")
            return
        }

        isSaving = true
        let resultado = await viewModel.cambiarPassword(id: cuenta.id, password: newPassword, confirmacion: confirmPassword)
        isSaving = false

        if resultado.exito {
            isPresented = false
            onActualizada(resultado.mensaje)
        } else {
            errorAlert = ErrorPeticionMensaje(mensaje: resultado.mensaje)
        }
    }
}
