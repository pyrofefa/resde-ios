import SwiftUI

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
                                    .background(Color.cardBackground)
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
                                .background(Color.cardBackground)
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
                                .background(Color.cardBackground)
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
                                .background(Color.cardBackground)
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
                                .background(Color.cardBackground)
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
                            .background(Color.cardBackground)
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
                            .background(Color.cardBackground)
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
                                .background(Color.selectedTint)
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
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
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
