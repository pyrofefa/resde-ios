//
//  HomeView.swift
//  resde
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedUbicacion: String = ""
    @State private var showUbicacionMenu = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HomeToolbar()

                    ScrollView {
                        HomeContent(
                            selectedUbicacion: $selectedUbicacion,
                            showUbicacionMenu: $showUbicacionMenu
                        )
                    }
                    .refreshable {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
            }
            .onAppear {
                if selectedUbicacion.isEmpty, let ubicaciones = authService.user?.ubicaciones {
                    if let firstLocation = ubicaciones.sorted(by: { $0.key < $1.key }).first {
                        selectedUbicacion = firstLocation.value
                        Task {
                            await authService.loadCarouselDataInParallel(ubicacionId: firstLocation.key)
                        }
                    }
                }
            }
            .onChange(of: selectedUbicacion) { oldValue, newValue in
                if !newValue.isEmpty, let ubicacionId = authService.user?.ubicaciones.first(where: { $0.value == newValue })?.key {
                    Task {
                        await authService.loadCarouselDataInParallel(ubicacionId: ubicacionId)
                    }
                }
            }
        }
    }
}

// MARK: - HomeContent
struct HomeContent: View {
    @EnvironmentObject var authService: AuthService
    @Binding var selectedUbicacion: String
    @Binding var showUbicacionMenu: Bool

    var body: some View {
        VStack(spacing: 0) {
            HomeHeader(user: authService.user)
                .padding(16)

            UbicacionCard(
                selectedUbicacion: $selectedUbicacion,
                ubicaciones: authService.user?.ubicaciones ?? [:],
                showMenu: $showUbicacionMenu
            )
            .padding(.horizontal, 16)

            InfoCarousel()
                .padding(.horizontal, 16)
                .padding(.top, 16)

            ResumenSection()
                .padding(.horizontal, 16)
                .padding(.top, 15)

            PanoramaSection()
                .padding(.horizontal, 16)
                .padding(.top, 15)

            ModulesSection(permissions: authService.user?.permissions ?? [])
                .padding(.horizontal, 16)
                .padding(.top, 15)
                .padding(.bottom, 24)
        }
    }
}

// MARK: - HomeToolbar
struct HomeToolbar: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Resde")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(Date(), style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: {
                authService.logout()
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(Color(red: 0.05, green: 0.2, blue: 0.35))
    }
}

// MARK: - HomeHeader
struct HomeHeader: View {
    let user: AuthData?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hola, \(user?.name ?? "Usuario") 👋")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(user?.residencial ?? "Mi Residencial")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
                Image("logoApp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
        }
    }
}

// MARK: - UbicacionCard
struct UbicacionCard: View {
    @Binding var selectedUbicacion: String
    let ubicaciones: [String: String]
    @Binding var showMenu: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ubicación")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(selectedUbicacion)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(showMenu ? 180 : 0))
            }
            .padding(12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    showMenu.toggle()
                }
            }

            if showMenu {
                UbicacionMenuContent(
                    selectedUbicacion: $selectedUbicacion,
                    ubicaciones: ubicaciones,
                    showMenu: $showMenu
                )
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct UbicacionMenuContent: View {
    @Binding var selectedUbicacion: String
    let ubicaciones: [String: String]
    @Binding var showMenu: Bool

    var body: some View {
        Divider()

        VStack(alignment: .leading, spacing: 0) {
            let sortedUbicaciones = Array(ubicaciones.sorted(by: { $0.key < $1.key }))
            ForEach(sortedUbicaciones.indices, id: \.self) { index in
                let value = sortedUbicaciones[index].value

                Button(action: {
                    selectedUbicacion = value
                    withAnimation {
                        showMenu = false
                    }
                }) {
                    HStack {
                        Text(value)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedUbicacion == value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(12)
                    .contentShape(Rectangle())
                }

                if index < sortedUbicaciones.count - 1 {
                    Divider().padding(.horizontal, 12)
                }
            }
        }
    }
}

// MARK: - InfoCarousel
struct CarouselItem {
    let id: Int
    let title: String
    let value: String
    let subtitle: String
    let description: String
    let backgroundColor: Color
    let titleColor: Color
}

struct InfoCarousel: View {
    @EnvironmentObject var authService: AuthService
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    var carouselItems: [CarouselItem] {
        let censo = authService.carouselData.censo
        let mascotas = authService.carouselData.mascotas
        let vehiculos = authService.carouselData.vehiculos?.total_vehiculos ?? 0
        let tarjetas = authService.carouselData.tarjetas?.total_tarjetas ?? 0
        let eventos = authService.carouselData.eventos?.total_eventos ?? 0

        var items: [CarouselItem] = []

        let estadoAdeudos = authService.carouselData.estadoAdeudos?.data
        let alCorriente = (estadoAdeudos?.saldoPendiente ?? 0) <= 0
        let cuotaMonto = estadoAdeudos?.cuotaActualMonto ?? 0
        let cuotaLabel = estadoAdeudos?.cuotaSub ?? "Enero – Agosto sin ningún pago registrado ($1,200)."
        let cuotaTitulo = estadoAdeudos?.cuotaActualLabel?.uppercased()
            ?? "CUOTA DE \((estadoAdeudos?.cuotaActual?.mes ?? "").uppercased())"
        items.append(CarouselItem(
            id: 0,
            title: cuotaTitulo,
            value: String(format: "$%.2f", cuotaMonto),
            subtitle: alCorriente ? "" : "Por pagar",
            description: cuotaLabel,
            backgroundColor: alCorriente ? Color(red: 0.9, green: 0.98, blue: 0.9) : Color.redTint,
            titleColor: alCorriente ? Color(red: 0.2, green: 0.7, blue: 0.2) : Color(red: 0.9, green: 0.2, blue: 0.2)
        ))

        items.append(CarouselItem(
            id: 1,
            title: "PRÓXIMAS RESERVAS",
            value: String(eventos),
            subtitle: eventos == 0 ? "Sin eventos próximos" : "Eventos programados",
            description: "Ver historial de reservas",
            backgroundColor: Color(red: 0.9, green: 0.95, blue: 1),
            titleColor: Color(red: 0, green: 0.4, blue: 0.9)
        ))

        let totalResidentes = (censo?.numero_residentes ?? 0)
        items.append(CarouselItem(
            id: 2,
            title: "CENSO",
            value: String(totalResidentes),
            subtitle: "Integrantes registrados",
            description: "Res: \(totalResidentes) | May: \(censo?.numero_mayores ?? 0) | Men: \(censo?.numero_menores ?? 0)",
            backgroundColor: Color(red: 1, green: 0.94, blue: 0.88),
            titleColor: Color(red: 1, green: 0.65, blue: 0)
        ))

        items.append(CarouselItem(
            id: 3,
            title: "VEHÍCULOS",
            value: String(vehiculos),
            subtitle: vehiculos == 1 ? "Auto autorizado" : "Autos autorizados",
            description: "Gestionar tags y placas",
            backgroundColor: Color(red: 0.95, green: 0.9, blue: 1),
            titleColor: Color(red: 0.6, green: 0.2, blue: 0.8)
        ))

        let totalMascotas = mascotas?.total_mascotas ?? 0
        items.append(CarouselItem(
            id: 4,
            title: "MASCOTAS",
            value: String(totalMascotas),
            subtitle: totalMascotas == 1 ? "Registrada" : "Registradas",
            description: "Ver reglamento de mascotas",
            backgroundColor: Color(red: 1, green: 0.97, blue: 0.9),
            titleColor: Color(red: 0.8, green: 0.6, blue: 0.2)
        ))

        items.append(CarouselItem(
            id: 5,
            title: "TARJETAS DE ACCESO",
            value: String(tarjetas),
            subtitle: tarjetas == 1 ? "Activa" : "Activas",
            description: "Reportar extravío o daño",
            backgroundColor: Color(red: 0.98, green: 0.96, blue: 0.92),
            titleColor: Color(red: 0.6, green: 0.5, blue: 0.3)
        ))

        return items
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                HStack(spacing: 16) {
                    ForEach(carouselItems, id: \.id) { item in
                        CarouselItemCard(item: item)
                            .frame(width: 300)
                    }
                }
                .offset(x: -CGFloat(currentPage) * (300 + 16) + dragOffset, y: 0)
                .animation(.easeOut(duration: 0.3), value: currentPage)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragOffset = gesture.translation.width
                        }
                        .onEnded { gesture in
                            let threshold: CGFloat = 50
                            if gesture.translation.width < -threshold && currentPage < carouselItems.count - 1 {
                                currentPage += 1
                            } else if gesture.translation.width > threshold && currentPage > 0 {
                                currentPage -= 1
                            }
                            dragOffset = 0
                        }
                )
                .frame(width: geometry.size.width, alignment: .leading)
            }
            .frame(height: 200)
            .clipped()

            HStack(spacing: 8) {
                ForEach(0..<carouselItems.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.3)) {
                                currentPage = index
                            }
                        }
                }
            }
        }
    }
}

struct CarouselItemCard: View {
    let item: CarouselItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(item.titleColor)
                .textCase(.uppercase)

            Spacer()

            Text(item.value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(item.titleColor)

            if !item.subtitle.isEmpty {
                Text(item.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.titleColor)
            }

            Text(item.description)
                .font(.system(size: 11))
                .foregroundColor(item.titleColor.opacity(0.7))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(item.backgroundColor)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

struct InfoCard: View {
    let index: Int

    var cardData: (title: String, amount: String, subtitle: String, color: Color) {
        switch index {
        case 0:
            return ("CUOTA DE AGOSTO", "$150.00", "Enero – Agosto sin ningún pago registrado ($1,200).", .red)
        case 1:
            return ("Próximo Pago", "$0.00", "", .primary)
        default:
            return ("Mantenimiento", "$0.00", "", .primary)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(cardData.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(cardData.color)
                .textCase(.uppercase)

            Spacer()

            Text(cardData.amount)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(cardData.color)

            if !cardData.subtitle.isEmpty {
                Text(cardData.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(cardData.color.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            index == 0
                ? Color(red: 1, green: 0.95, blue: 0.95)
                : Color.cardBackground
        )
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - ResumenSection
struct ResumenSection: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESUMEN AÑO ACTUAL")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ResumenCards(estadoAdeudos: authService.carouselData.estadoAdeudos)
        }
    }
}

struct ResumenCards: View {
    let estadoAdeudos: EstadoAdeudosResponse?

    var body: some View {
        let validado = estadoAdeudos?.data?.validadoMonto ?? estadoAdeudos?.data?.montoValidadoAnio ?? 0
        let parcial = estadoAdeudos?.data?.montoParcial ?? 0
        let pendiente = estadoAdeudos?.data?.montoPendiente ?? 0
        let faltante = estadoAdeudos?.data?.montoFaltante ?? 0
        let validadoCount = estadoAdeudos?.data?.cuotasValidadasCount ?? 0
        let parcialCount = estadoAdeudos?.data?.cuotasParcialesCount ?? 0
        let pendienteCount = estadoAdeudos?.data?.cuotasPendientesCount ?? 0
        let faltanteCount = estadoAdeudos?.data?.cuotasFaltantesCount ?? 0

        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ResumenCardItem(
                    title: "VALIDADO",
                    amount: String(format: "$%.2f", validado),
                    subtitle: estadoAdeudos?.data?.validadoLabel ?? "\(validadoCount) meses cubiertos",
                    backgroundColor: Color(red: 0.9, green: 0.98, blue: 0.9),
                    titleColor: Color(red: 0.2, green: 0.7, blue: 0.2)
                )

                ResumenCardItem(
                    title: "PARCIAL",
                    amount: String(format: "$%.2f", parcial),
                    subtitle: estadoAdeudos?.data?.parcialLabel ?? "\(parcialCount) meses incompletos",
                    backgroundColor: Color(red: 0.98, green: 0.94, blue: 0.88),
                    titleColor: Color(red: 1, green: 0.65, blue: 0)
                )
            }

            HStack(spacing: 12) {
                ResumenCardItem(
                    title: "PENDIENTE DE VALIDAR",
                    amount: String(format: "$%.2f", pendiente),
                    subtitle: estadoAdeudos?.data?.pendienteLabel ?? "\(pendienteCount) meses sin validar",
                    backgroundColor: Color(red: 1, green: 0.98, blue: 0.88),
                    titleColor: Color(red: 1, green: 0.8, blue: 0)
                )

                ResumenCardItem(
                    title: "SIN PAGO",
                    amount: String(format: "$%.2f", faltante),
                    subtitle: estadoAdeudos?.data?.faltanteLabel ?? "\(faltanteCount) meses sin registrar",
                    backgroundColor: Color(red: 1, green: 0.9, blue: 0.9),
                    titleColor: Color(red: 0.9, green: 0.2, blue: 0.2)
                )
            }
        }
    }
}

struct ResumenCardItem: View {
    let title: String
    let amount: String
    let subtitle: String
    let backgroundColor: Color
    let titleColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(titleColor)
                .textCase(.uppercase)

            Text(amount)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(titleColor)

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - PanoramaSection
struct PanoramaSection: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PANORAMA AÑO ACTUAL")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            PanoramaContent(
                mesesDetalle: authService.carouselData.estadoAdeudos?.data?.mesesDetalle ?? [],
                cuotaSub: authService.carouselData.estadoAdeudos?.data?.cuotaSub
            )
        }
    }
}

struct PanoramaContent: View {
    let mesesDetalle: [MesDetalle]
    let cuotaSub: String?
    let months = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"]

    func colorForStatus(_ status: String?) -> Color {
        switch status {
        case "validado":
            return Color(red: 0.2, green: 0.7, blue: 0.2)
        case "parcial":
            return Color(red: 1, green: 0.65, blue: 0)
        case "pendiente":
            return Color(red: 1, green: 0.8, blue: 0)
        case "faltante":
            return Color(red: 0.9, green: 0.2, blue: 0.2)
        case "futuro":
            return Color.gray.opacity(0.5)
        default:
            return Color.gray.opacity(0.5)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(cuotaSub ?? "Enero – Agosto sin ningún pago registrado ($1,200).")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(0..<12, id: \.self) { index in
                    let mesData = mesesDetalle.first(where: { $0.numero == index + 1 })
                    Button(action: {}) {
                        Text(months[index])
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(colorForStatus(mesData?.estatus))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - ModulesSection
struct ModulesSection: View {
    @EnvironmentObject var authService: AuthService
    let permissions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("MÓDULOS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ModuleSectionGroup(
                title: "PAGOS Y FINANZAS",
                permissions: permissions,
                modules: [
                    ("pago.create", "Pagos", "creditcard.fill"),
                    ("pago.create", "Mensualidades", "calendar"),
                    ("reporte.view", "Reportes", "chart.bar.fill")
                ]
            )

            ModuleSectionGroup(
                title: "MI HOGAR",
                permissions: permissions,
                modules: [
                    ("censo.manage", "Censo", "person.2.fill"),
                    ("cuentasv.manage", "Cuentas Vinculadas", "building.2.fill"),
                    ("mascotas.manage", "Mascotas", "pawprint.fill"),
                    ("vehiculos.manage", "Vehículos", "car.fill")
                ]
            )

            ModuleSectionGroup(
                title: "COMUNIDAD",
                permissions: permissions,
                modules: [
                    ("evento.manage", "Eventos", "calendar"),
                    ("queja.manage", "Quejas", "exclamationmark.bubble.fill")
                ]
            )

            ModuleSectionGroup(
                title: "ACCESOS",
                permissions: permissions,
                modules: [
                    ("tarjetas.manage", "Tarjetas de acceso", "wifi.router.fill")
                ]
            )
        }
        .navigationDestination(for: String.self) { moduleName in
            getModuleView(for: moduleName)
        }
    }

    @ViewBuilder
    private func getModuleView(for title: String) -> some View {
        switch title {
        case "Pagos":
            PagosView()
        case "Mensualidades":
            MensualidadesView()
        case "Reportes":
            ReportesView()
        case "Censo":
            CensoView()
        case "Cuentas Vinculadas":
            CuentasView()
        case "Mascotas":
            MascotasView()
        case "Vehículos":
            VehiculosView()
        case "Eventos":
            EventosView()
        case "Quejas":
            QuejasView()
        case "Tarjetas de acceso":
            TarjetasView()
        default:
            PagosView()
        }
    }
}

struct ModuleSectionGroup: View {
    let title: String
    let permissions: [String]
    let modules: [(permission: String, title: String, icon: String)]

    var visibleModules: [(String, String)] {
        modules.compactMap { module in
            if permissions.contains(module.permission) {
                return (module.title, module.icon)
            }
            return nil
        }
    }

    var body: some View {
        if !visibleModules.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .textCase(.uppercase)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(visibleModules, id: \.0) { module in
                        NavigationLink(value: module.0) {
                            ModuleCard(title: module.0, icon: module.1)
                        }
                    }
                }
            }
        }
    }
}

struct ModuleCard: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService(mockData: true))
}
