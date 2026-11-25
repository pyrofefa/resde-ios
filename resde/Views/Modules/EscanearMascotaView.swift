import SwiftUI
import AVFoundation

struct EscanearMascotaView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = EscanearMascotaViewModel()

    @State private var mostrarEscaner = false
    @State private var aviso: String?
    @State private var permisoDenegado = false
    @State private var errorCamara: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        SeccionCargando(logo: authService.user?.logo, height: 200)
                            .frame(maxWidth: .infinity)
                    } else if let mascota = viewModel.mascota {
                        tarjetaResultado(mascota)
                    } else {
                        indicacion
                    }
                }
                .padding(16)
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .fullScreenCover(isPresented: $mostrarEscaner) { escaner }
        .alert("Aviso", isPresented: Binding(
            get: { aviso != nil },
            set: { if !$0 { aviso = nil } }
        )) {
            Button("Intentar de nuevo") {
                aviso = nil
                iniciarEscaneo()
            }
            Button("Regresar", role: .cancel) { aviso = nil }
        } message: {
            Text(aviso ?? "")
        }
        .alert("Cámara no disponible", isPresented: $permisoDenegado) {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se requiere permiso de cámara para escanear códigos QR. Actívalo en Ajustes.")
        }
        .alert("Cámara", isPresented: Binding(
            get: { errorCamara != nil },
            set: { if !$0 { errorCamara = nil } }
        )) {
            Button("Entendido", role: .cancel) { errorCamara = nil }
        } message: {
            Text(errorCamara ?? "")
        }
    }

    // MARK: - Partes

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text("Identificar Mascota")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.05, green: 0.2, blue: 0.35))
    }

    private var indicacion: some View {
        VStack(spacing: 16) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("Identificar Mascota")
                .font(.system(size: 20, weight: .bold))

            Text("Escanea el código QR de una mascota para consultar su ficha, ubicación y residencial.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            botonEscanear("Escanear Código QR")
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    private func tarjetaResultado(_ mascota: MascotaQr) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 14) {
                ImagenAutenticada(url: mascota.urlFoto) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                }
                .frame(width: 140, height: 140)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(mascota.nombre)
                    .font(.system(size: 22, weight: .bold))

                Text(mascota.textoEspecie)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())

                Divider()

                dato("DIRECCIÓN", mascota.textoDireccion, icono: "house.fill")
                dato("RESIDENCIAL", mascota.textoResidencial, icono: "building.2.fill")
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2), lineWidth: 1))

            botonEscanear("Escanear otro código QR")
        }
    }

    private func dato(_ titulo: String, _ valor: String, icono: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icono)
                .foregroundColor(.blue)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(valor)
                    .font(.system(size: 15, weight: .semibold))
            }
            Spacer()
        }
    }

    private func botonEscanear(_ titulo: String) -> some View {
        Button(action: iniciarEscaneo) {
            HStack(spacing: 8) {
                Image(systemName: "qrcode.viewfinder")
                Text(titulo)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color(red: 0.0, green: 0.4, blue: 0.7))
            .cornerRadius(25)
        }
        .disabled(viewModel.isLoading)
    }

    private var escaner: some View {
        ZStack(alignment: .top) {
            QRScannerView(
                onCodigo: { codigo in
                    mostrarEscaner = false
                    Task { await consultar(codigo) }
                },
                onError: { mensaje in
                    mostrarEscaner = false
                    errorCamara = mensaje
                }
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: { mostrarEscaner = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                }
                .padding(16)

                Spacer()

                Text("Escanea el código QR de la mascota")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Acciones

    private func iniciarEscaneo() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            mostrarEscaner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { concedido in
                DispatchQueue.main.async {
                    if concedido { mostrarEscaner = true } else { permisoDenegado = true }
                }
            }
        default:
            permisoDenegado = true
        }
    }

    private func consultar(_ codigo: String) async {
        switch await viewModel.consultar(codigo: codigo) {
        case .encontrada:
            break
        case .aviso(let mensaje):
            aviso = mensaje
        }
    }
}
