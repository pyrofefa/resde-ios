import SwiftUI

struct CuentasView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CuentasViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text("Cuentas Vinculadas")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(16)
            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UBICACIÓN")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(authService.user?.ubicaciones.first?.value ?? "N/A")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Buscar por nombre o correo", text: $viewModel.searchText)
                            .font(.system(size: 15))
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(40)
                    } else {
                        Text("\(viewModel.filteredCuentas.count) cuenta(s) vinculada(s)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredCuentas) { cuenta in
                                Button(action: { viewModel.selectedCuenta = cuenta }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(cuenta.nombre_completo)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Text(cuenta.email)
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
        .navigationBarBackButtonHidden()
        .sheet(item: $viewModel.selectedCuenta) { cuenta in
            CuentaDetailSheet(cuenta: cuenta)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            guard let ubicacionId = Int(authService.user?.ubicaciones.first?.key ?? "") else { return }
            Task {
                await viewModel.loadCuentas(ubicacionId: ubicacionId)
            }
        }
    }
}

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
                    .background(Color(red: 0.8, green: 0.9, blue: 1.0))
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
                                .background(Color(red: 0.9, green: 0.95, blue: 1.0))
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
                            .background(Color(red: 1.0, green: 0.9, blue: 0.9))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
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
                            .background(Color.white)
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
                            .background(Color.white)
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
            .background(Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1))
            .navigationBarHidden(true)
        }
    }
}

struct EditarCuentaSheet: View {

    let cuenta: Cuenta

    @Binding var isPresented: Bool

    @State private var step = 1

    @State private var nombre = ""
    @State private var apellidoPaterno = ""
    @State private var apellidoMaterno = ""
    @State private var email = ""
    @State private var telefono = ""

    @State private var rentaCasa = false

    @State private var registrarPago = false
    @State private var gestionarEventos = true
    @State private var gestionarQuejas = false
    @State private var verReporte = false
    @State private var gestionarVehiculos = true
    @State private var gestionarCenso = false
    @State private var gestionTarjetas = true

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - CONTENIDO

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - ENCABEZADO

                    HStack {

                        Text("Editar cuenta vinculada")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }

                    // MARK: - INDICADOR DE PASOS

                    HStack(spacing: 8) {

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                Color(
                                    red: 0.0,
                                    green: 0.4,
                                    blue: 0.7
                                )
                            )
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                step == 2
                                ? Color(
                                    red: 0.0,
                                    green: 0.4,
                                    blue: 0.7
                                )
                                : Color.gray.opacity(0.3)
                            )
                            .frame(height: 8)
                    }

                    // MARK: - PASO 1

                    if step == 1 {

                        VStack(alignment: .leading, spacing: 16) {

                            Text("DATOS DEL USUARIO VINCULADO")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .textCase(.uppercase)

                            // Nombre
                            VStack(alignment: .leading, spacing: 4) {

                                Text("Nombre")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField("Nombre", text: $nombre)
                                    .font(.system(size: 16))
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }

                            // Apellido Paterno
                            VStack(alignment: .leading, spacing: 4) {

                                Text("Apellido Paterno")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField(
                                    "Apellido Paterno",
                                    text: $apellidoPaterno
                                )
                                .font(.system(size: 16))
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            Color.gray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }

                            // Apellido Materno
                            VStack(alignment: .leading, spacing: 4) {

                                Text("Apellido Materno")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField(
                                    "Apellido Materno",
                                    text: $apellidoMaterno
                                )
                                .font(.system(size: 16))
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            Color.gray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }

                            // Correo
                            VStack(alignment: .leading, spacing: 4) {

                                Text("Correo Electrónico")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField(
                                    "Correo Electrónico",
                                    text: $email
                                )
                                .font(.system(size: 16))
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            Color.gray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }

                            // Teléfono
                            VStack(alignment: .leading, spacing: 4) {

                                Text("Teléfono (10 dígitos)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)

                                TextField(
                                    "Teléfono",
                                    text: $telefono
                                )
                                .font(.system(size: 16))
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            Color.gray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }

                            // Renta la casa
                            HStack(spacing: 12) {

                                Image(
                                    systemName: rentaCasa
                                    ? "checkmark.square.fill"
                                    : "square"
                                )
                                .font(.system(size: 18))
                                .foregroundColor(
                                    rentaCasa
                                    ? Color(
                                        red: 0.0,
                                        green: 0.4,
                                        blue: 0.7
                                    )
                                    : .gray
                                )

                                Text("Renta la casa")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                rentaCasa.toggle()
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        Color.gray.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }

                    // MARK: - PASO 2

                    } else {

                        VStack(alignment: .leading, spacing: 16) {

                            VStack(alignment: .leading, spacing: 8) {

                                Text("PERMISOS Y ACCESO")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .textCase(.uppercase)

                                Text(
                                    "Ajusta los módulos a los que esta cuenta vinculada puede acceder."
                                )
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            }

                            VStack(spacing: 16) {

                                PermissionToggleRow(
                                    label: "Registrar pago",
                                    isOn: $registrarPago
                                )

                                PermissionToggleRow(
                                    label: "Gestionar eventos",
                                    isOn: $gestionarEventos
                                )

                                PermissionToggleRow(
                                    label: "Gestionar quejas",
                                    isOn: $gestionarQuejas
                                )

                                PermissionToggleRow(
                                    label: "Ver Reporte",
                                    isOn: $verReporte
                                )

                                PermissionToggleRow(
                                    label: "Gestionar vehículos",
                                    isOn: $gestionarVehiculos
                                )

                                PermissionToggleRow(
                                    label: "Gestionar Censo",
                                    isOn: $gestionarCenso
                                )

                                PermissionToggleRow(
                                    label: "Gestión de tarjetas",
                                    isOn: $gestionTarjetas
                                )
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.gray.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(16)
            }

            // MARK: - BOTONES INFERIORES

            VStack(spacing: 12) {

                if step == 1 {

                    Button(action: {
                        step = 2
                    }) {

                        Text("Siguiente")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                Color(
                                    red: 0.0,
                                    green: 0.4,
                                    blue: 0.7
                                )
                            )
                            .cornerRadius(12)
                    }

                } else {

                    HStack(spacing: 12) {

                        Button(action: {
                            step = 1
                        }) {

                            Text("Anterior")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(
                                    Color(
                                        red: 0.9,
                                        green: 0.85,
                                        blue: 1.0
                                    )
                                )
                                .cornerRadius(12)
                        }

                        Button(action: {

                            // Aquí puedes guardar los cambios
                            isPresented = false

                        }) {

                            Text("Guardar Cambios")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(
                                    Color(
                                        red: 0.0,
                                        green: 0.4,
                                        blue: 0.7
                                    )
                                )
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .background(
                Color(
                    .sRGB,
                    red: 0.98,
                    green: 0.98,
                    blue: 0.98,
                    opacity: 1
                )
            )
        }
        .background(
            Color(
                .sRGB,
                red: 0.98,
                green: 0.98,
                blue: 0.98,
                opacity: 1
            )
        )
        .onAppear {

            nombre = cuenta.nombre
            apellidoPaterno = cuenta.apellido_paterno ?? ""
            apellidoMaterno = cuenta.apellido_materno ?? ""
            email = cuenta.email
            telefono = cuenta.telefono ?? ""
            rentaCasa = cuenta.renta == 1
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
                .tint(Color(red: 0.0, green: 0.4, blue: 0.7))
        }
    }
}

#Preview {
    CuentasView()
        .environmentObject(AuthService(mockData: true))
}
