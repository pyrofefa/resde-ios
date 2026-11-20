import SwiftUI

struct EditarCuentaSheet: View {
    let cuenta: Cuenta
    @ObservedObject var viewModel: CuentasViewModel
    @Binding var isPresented: Bool
    let onGuardado: (String) -> Void

    @State private var step = 1
    @State private var nombre = ""
    @State private var apellidoPaterno = ""
    @State private var apellidoMaterno = ""
    @State private var email = ""
    @State private var telefono = ""
    @State private var rentaCasa = false

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
                        Text("Editar cuenta vinculada")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }

                    IndicadorPasos(total: 2, actual: step)

                    if step == 1 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DATOS DEL USUARIO VINCULADO")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            CampoFormulario(titulo: "Nombre", texto: $nombre)
                            CampoFormulario(titulo: "Apellido Paterno", texto: $apellidoPaterno)
                            CampoFormulario(titulo: "Apellido Materno", texto: $apellidoMaterno)
                            CampoFormulario(titulo: "Correo Electrónico", texto: $email, teclado: .emailAddress, minusculas: true)
                            CampoFormulario(titulo: "Teléfono (10 dígitos)", texto: $telefono, teclado: .numberPad)
                            CheckRenta(activo: $rentaCasa)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PERMISOS Y ACCESO")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Ajusta los módulos a los que esta cuenta vinculada puede acceder.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            PermisosSwitchList(permisos: permisos, cargando: cargandoPermisos, seleccionados: $seleccionados)
                        }
                    }
                }
                .padding(16)
            }

            VStack(spacing: 12) {
                if step == 1 {
                    BotonAccion(titulo: "Siguiente") { siguiente() }
                } else {
                    HStack(spacing: 12) {
                        BotonAccion(titulo: "Anterior", secundario: true) { step = 1 }
                        BotonAccion(titulo: isSaving ? "Guardando..." : "Guardar Cambios", cargando: isSaving) {
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
            nombre = cuenta.nombre
            apellidoPaterno = cuenta.apellido_paterno ?? ""
            apellidoMaterno = cuenta.apellido_materno ?? ""
            email = cuenta.email
            telefono = cuenta.telefono ?? ""
            rentaCasa = cuenta.renta == 1

            let lista = await viewModel.cargarPermisosUsuario(userId: cuenta.id)
            permisos = lista
            seleccionados = Set(lista.filter { $0.asignado == true }.map(\.id))
            cargandoPermisos = false
        }
    }

    private func siguiente() {
        let campos = [nombre, apellidoPaterno, apellidoMaterno, email, telefono]
        if campos.contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            errorAlert = ErrorPeticionMensaje(mensaje: "Por favor completa todos los campos")
            return
        }
        step = 2
    }

    private func guardar() async {
        isSaving = true
        let params: [String: Any] = [
            "nombre": nombre.trimmingCharacters(in: .whitespaces),
            "apellido_paterno": apellidoPaterno.trimmingCharacters(in: .whitespaces),
            "apellido_materno": apellidoMaterno.trimmingCharacters(in: .whitespaces),
            "email": email.trimmingCharacters(in: .whitespaces),
            "telefono": telefono.trimmingCharacters(in: .whitespaces),
            "renta": rentaCasa,
            "permisos": Array(seleccionados).sorted()
        ]
        let resultado = await viewModel.actualizarCuenta(id: cuenta.id, params)
        isSaving = false

        if resultado.exito {
            isPresented = false
            onGuardado(resultado.mensaje)
        } else {
            errorAlert = ErrorPeticionMensaje(mensaje: resultado.mensaje)
        }
    }
}

struct PermissionToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(.accionPrimaria)
        }
    }
}
