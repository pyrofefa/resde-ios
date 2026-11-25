import SwiftUI
import MapKit

struct MapaResidencialView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = MapaResidencialViewModel()

    private let meses = [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ]

    @State private var mesIndex = Calendar.current.component(.month, from: Date()) - 1
    @State private var camara: MapCameraPosition = .automatic
    @State private var regionActual: MKCoordinateRegion?
    @State private var toast: String?
    @State private var errorAlert: ErrorPeticionMensaje?

    private var mesClave: Int { mesIndex + 1 }
    private var conteos: ConteoMes { viewModel.conteos(mes: mesClave) }
    private var ubicacionesConPin: [(ubicacion: UbicacionMapa, coordenada: CLLocationCoordinate2D)] {
        (viewModel.data?.ubicaciones ?? []).compactMap { u in
            u.coordenada.map { (u, $0) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            selectores
            leyenda

            ZStack(alignment: .bottom) {
                mapa

                if viewModel.isLoading {
                    Color.black.opacity(0.25)
                    SeccionCargando(logo: authService.user?.logo, height: 120)
                }

                if let toast {
                    SuccessToast(message: toast)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task { await cargarInicial() }
        .sheet(item: $errorAlert) { error in
            ErrorPeticionDialog(mensaje: error.mensaje, onCerrar: {
                errorAlert = nil
                viewModel.errorMessage = nil
            })
            .presentationDetents([.fraction(0.45)])
        }
        .onChange(of: viewModel.errorMessage) { _, mensaje in
            if let mensaje { errorAlert = ErrorPeticionMensaje(mensaje: mensaje) }
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
            Text("Mapa Residencial")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button(action: { Task { await actualizar() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(16)
        .background(Color(red: 0.05, green: 0.2, blue: 0.35).ignoresSafeArea(edges: .top))
    }

    private var selectores: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(viewModel.aniosDisponibles, id: \.self) { anio in
                    Button(String(anio)) { Task { await cambiarAnio(anio) } }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.anioSeleccionado.map(String.init) ?? "—")
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.12))
                .clipShape(Capsule())
            }
            .disabled(viewModel.data == nil)

            HStack(spacing: 0) {
                Button(action: { mesIndex = mesIndex > 0 ? mesIndex - 1 : 11 }) {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                }
                Text(meses[mesIndex])
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                Button(action: { mesIndex = mesIndex < 11 ? mesIndex + 1 : 0 }) {
                    Image(systemName: "chevron.right")
                        .frame(width: 36, height: 36)
                }
            }
            .foregroundColor(.primary)
            .background(Color.cardBackground)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var leyenda: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
            itemLeyenda(.alCorriente, "Al corriente: \(conteos.alCorriente)")
            itemLeyenda(.parcial, "Pago parcial: \(conteos.parcial)")
            itemLeyenda(.adeudo, "Con adeudo: \(conteos.adeudo)")
            itemLeyenda(.convenio, "Convenio: \(conteos.convenio)")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func itemLeyenda(_ estado: EstadoSemaforo, _ texto: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(estado.color)
                .frame(width: 12, height: 12)
            Text(texto)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            Spacer(minLength: 0)
        }
    }

    private var mapa: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $camara) {
                ForEach(ubicacionesConPin, id: \.ubicacion.id) { item in
                    Annotation(
                        "",
                        coordinate: item.coordenada,
                        anchor: .bottom
                    ) {
                        CasaPin(
                            numero: item.ubicacion.numero,
                            color: item.ubicacion.estado(mes: mesClave).color,
                            esPropia: item.ubicacion.esPropia
                        )
                    }
                }
            }
            .mapStyle(.hybrid)
            .onMapCameraChange { contexto in
                regionActual = contexto.region
            }

            VStack(spacing: 0) {
                botonZoom("plus") { zoom(factor: 0.5) }
                Divider().frame(width: 36)
                botonZoom("minus") { zoom(factor: 2) }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(12)
        }
    }

    private func botonZoom(_ icono: String, _ accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Image(systemName: icono)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 40, height: 40)
        }
        .foregroundColor(.primary)
    }

    // MARK: - Acciones

    private func cargarInicial() async {
        guard viewModel.data == nil else { return }
        if await viewModel.cargar(anio: nil) { ajustarCamara() }
    }

    private func cambiarAnio(_ anio: Int) async {
        if await viewModel.cargar(anio: anio) { ajustarCamara() }
    }

    private func actualizar() async {
        let anio = viewModel.anioSeleccionado
        if await viewModel.cargar(anio: anio) {
            ajustarCamara()
            mostrarToast("Mapa actualizado para \(meses[mesIndex]) \(viewModel.anioSeleccionado ?? 0)")
        }
    }

    private func mostrarToast(_ mensaje: String) {
        withAnimation { toast = mensaje }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { toast = nil }
        }
    }

    private func zoom(factor: Double) {
        guard let region = regionActual else { return }
        let span = MKCoordinateSpan(
            latitudeDelta: min(max(region.span.latitudeDelta * factor, 0.0005), 120),
            longitudeDelta: min(max(region.span.longitudeDelta * factor, 0.0005), 120)
        )
        withAnimation { camara = .region(MKCoordinateRegion(center: region.center, span: span)) }
    }

    /// Encuadra todas las casas con coordenadas válidas (con margen); si no hay, usa el centro.
    private func ajustarCamara() {
        let puntos = ubicacionesConPin.map { MKMapPoint($0.coordenada) }
        if let primero = puntos.first {
            var rect = MKMapRect(origin: primero, size: MKMapSize(width: 0, height: 0))
            for punto in puntos.dropFirst() {
                rect = rect.union(MKMapRect(origin: punto, size: MKMapSize(width: 0, height: 0)))
            }
            // Margen equivalente al padding de Android; mínimo para una sola casa.
            let ancho = max(rect.size.width, 400)
            let alto = max(rect.size.height, 400)
            let ajustado = MKMapRect(
                x: rect.midX - ancho / 2, y: rect.midY - alto / 2,
                width: ancho, height: alto
            ).insetBy(dx: -ancho * 0.25, dy: -alto * 0.25)
            withAnimation { camara = .rect(ajustado) }
        } else if let centro = viewModel.data?.centro {
            camara = .region(MKCoordinateRegion(
                center: centro,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            ))
        }
    }
}

// MARK: - Pin en forma de casa

private struct CasaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let techoAlto = rect.height * 0.42
        // Techo
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + techoAlto))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + techoAlto))
        path.closeSubpath()
        // Cuerpo
        path.addRoundedRect(
            in: CGRect(
                x: rect.minX + rect.width * 0.08,
                y: rect.minY + techoAlto - 1,
                width: rect.width * 0.84,
                height: rect.height - techoAlto + 1
            ),
            cornerSize: CGSize(width: 4, height: 4)
        )
        return path
    }
}

private struct CasaPin: View {
    let numero: String
    let color: Color
    let esPropia: Bool

    private let dorado = Color(.sRGB, red: 0.98, green: 0.80, blue: 0.08, opacity: 1)

    var body: some View {
        ZStack {
            CasaShape()
                .fill(color)
            CasaShape()
                .stroke(esPropia ? dorado : Color.white, lineWidth: esPropia ? 3 : 1.5)

            Text(numero)
                .font(.system(size: numero.count > 3 ? 9 : 11, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .offset(y: 7)
        }
        .frame(width: esPropia ? 40 : 34, height: esPropia ? 40 : 34)
        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
        .accessibilityLabel("Casa \(numero)\(esPropia ? ", tu vivienda" : "")")
    }
}
