import SwiftUI

/// Alta de cuenta vinculada en 3 pasos (datos, contraseña, permisos), igual que Android.
struct NuevaCuentaSheet: View {
    @ObservedObject var viewModel: CuentasViewModel
    let ubicacionId: Int
    let ubicacionNombre: String
    @Binding var isPresented: Bool
    let onCreada: (String) -> Void

    @State private var step = 1
    @State private var nombre = ""
    @State private var apellidoPaterno = ""
    @State private var apellidoMaterno = ""
    @State private var email = ""
    @State private var telefono = ""
    @State private var rentaCasa = false
    @State private var password = ""
    @State private var confirmacion = ""
    @State private var mostrarPassword = false

    @State private var permisos: [PermisoVinculado] = []
    @State private var seleccionados: Set<Int> = []
    @State private var cargandoPermisos = true
    @State private var isSaving = false
    @State private var errorAlert: ErrorPeticionMensaje?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Nueva cuenta vinculada")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }

                    IndicadorPasos(total: 3, actual: step)

                    switch step {
                    case 1: pasoDatos
                    case 2: pasoContrasena
                    default: pasoPermisos
                    }
                }
                .padding(16)
            }

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    if step > 1 {
                        BotonAccion(titulo: "Anterior", secundario: true) { step -= 1 }
                    }
                    BotonAccion(
                        titulo: step == 3 ? (isSaving ? "Guardando..." : "Finalizar y Vincular") : "Siguiente",
                        cargando: isSaving
                    ) {
                        if step < 3 {
                            if validarPasoActual() { step += 1 }
                        } else {
                            Task { await guardar() }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .onChange(of: telefono) { _, nuevo in
            let digitos = String(nuevo.filter(\.isNumber).prefix(10))
            if digitos != nuevo { telefono = digitos }
        }
        .sheet(item: $errorAlert) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: { errorAlert = nil })
                .presentationDetents([.fraction(0.45)])
        }
        .task {
            permisos = await viewModel.cargarPermisos()
            cargandoPermisos = false
        }
    }

    // MARK: - Pasos

    private var pasoDatos: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DATOS DEL USUARIO VINCULADO")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                Image(systemName: "house.fill").foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("UBICACIÓN")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(ubicacionNombre)
                        .font(.system(size: 15, weight: .semibold))
                }
                Spacer()
            }
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(8)

            CampoFormulario(titulo: "Nombre", texto: $nombre)
            CampoFormulario(titulo: "Apellido Paterno", texto: $apellidoPaterno)
            CampoFormulario(titulo: "Apellido Materno", texto: $apellidoMaterno)
            CampoFormulario(titulo: "Correo Electrónico", texto: $email, teclado: .emailAddress, minusculas: true)
            CampoFormulario(titulo: "Teléfono (10 dígitos)", texto: $telefono, teclado: .numberPad)
            CheckRenta(activo: $rentaCasa)
        }
    }

    private var pasoContrasena: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONTRASEÑA DE ACCESO")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            Text("Define la contraseña con la que ingresará esta cuenta. Mínimo 8 caracteres.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            CampoContrasena(titulo: "Contraseña", texto: $password, mostrar: $mostrarPassword)
            CampoContrasena(titulo: "Confirmar contraseña", texto: $confirmacion, mostrar: $mostrarPassword)
        }
    }

    private var pasoPermisos: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("PERMISOS Y ACCESO")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Elige los módulos a los que esta cuenta vinculada podrá acceder.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            PermisosSwitchList(permisos: permisos, cargando: cargandoPermisos, seleccionados: $seleccionados)
        }
    }

    // MARK: - Validación y envío

    private func validarPasoActual() -> Bool {
        switch step {
        case 1:
            if [nombre, email, telefono].contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                errorAlert = ErrorPeticionMensaje(mensaje: "Por favor completa los campos obligatorios")
                return false
            }
            if telefono.count != 10 {
                errorAlert = ErrorPeticionMensaje(mensaje: "El teléfono debe tener 10 dígitos")
                return false
            }
        case 2:
            if password.count < 8 {
                errorAlert = ErrorPeticionMensaje(mensaje: "La contraseña debe tener al menos 8 caracteres")
                return false
            }
            if password != confirmacion {
                errorAlert = ErrorPeticionMensaje(mensaje: "Las contraseñas no coinciden")
                return false
            }
        default:
            break
        }
        return true
    }

    private func guardar() async {
        isSaving = true
        let params: [String: Any] = [
            "nombre": nombre.trimmingCharacters(in: .whitespaces),
            "apellido_paterno": apellidoPaterno.trimmingCharacters(in: .whitespaces),
            "apellido_materno": apellidoMaterno.trimmingCharacters(in: .whitespaces),
            "email": email.trimmingCharacters(in: .whitespaces),
            "telefono": telefono.trimmingCharacters(in: .whitespaces),
            "password": password,
            "password_confirmation": confirmacion,
            "ubicacion_id": ubicacionId,
            "renta": rentaCasa,
            "permisos": Array(seleccionados).sorted()
        ]
        let resultado = await viewModel.crearCuenta(params)
        isSaving = false

        if resultado.exito {
            isPresented = false
            onCreada(resultado.mensaje)
        } else {
            errorAlert = ErrorPeticionMensaje(mensaje: resultado.mensaje)
        }
    }
}
