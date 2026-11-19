//
//  VinculadoFormComponents.swift
//  resde
//

import SwiftUI

extension Color {
    /// Azul de acción principal de la app.
    static let accionPrimaria = Color(red: 0.0, green: 0.4, blue: 0.7)
}

struct CampoFormulario: View {
    let titulo: String
    @Binding var texto: String
    var teclado: UIKeyboardType = .default
    var minusculas = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            TextField(titulo, text: $texto)
                .font(.system(size: 16))
                .keyboardType(teclado)
                .textInputAutocapitalization(minusculas ? .never : .words)
                .autocorrectionDisabled(minusculas)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        }
    }
}

struct CampoContrasena: View {
    let titulo: String
    @Binding var texto: String
    @Binding var mostrar: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            HStack {
                Group {
                    if mostrar {
                        TextField(titulo, text: $texto)
                    } else {
                        SecureField(titulo, text: $texto)
                    }
                }
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button(action: { mostrar.toggle() }) {
                    Image(systemName: mostrar ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        }
    }
}

struct CheckRenta: View {
    @Binding var activo: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activo ? "checkmark.square.fill" : "square")
                .font(.system(size: 18))
                .foregroundColor(activo ? .accionPrimaria : .gray)
            Text("Renta la casa")
                .font(.system(size: 16))
                .foregroundColor(.primary)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { activo.toggle() }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }
}

struct IndicadorPasos: View {
    let total: Int
    let actual: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { paso in
                RoundedRectangle(cornerRadius: 4)
                    .fill(paso <= actual ? Color.accionPrimaria : Color.gray.opacity(0.3))
                    .frame(height: 8)
            }
        }
    }
}

/// Lista de permisos con interruptores. Los permisos vienen del servidor.
struct PermisosSwitchList: View {
    let permisos: [PermisoVinculado]
    let cargando: Bool
    @Binding var seleccionados: Set<Int>

    var body: some View {
        VStack(spacing: 16) {
            if cargando {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(8)
            } else if permisos.isEmpty {
                Text("No hay permisos disponibles")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                ForEach(permisos) { permiso in
                    PermissionToggleRow(
                        label: permiso.nombre,
                        isOn: Binding(
                            get: { seleccionados.contains(permiso.id) },
                            set: { activo in
                                if activo { seleccionados.insert(permiso.id) } else { seleccionados.remove(permiso.id) }
                            }
                        )
                    )
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct BotonAccion: View {
    let titulo: String
    var cargando = false
    var secundario = false
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 8) {
                if cargando { ProgressView().tint(.white) }
                Text(titulo)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(secundario ? .primary : .white)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(secundario ? Color.selectedTint : Color.accionPrimaria)
            .cornerRadius(12)
        }
        .disabled(cargando)
    }
}
