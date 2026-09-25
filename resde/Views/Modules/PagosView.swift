//
//  PagosView.swift
//  resde
//

import SwiftUI

struct PagosView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var selectedUbicacion = "Todas las ubicaciones"
    @State private var isLoading = true
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showYearPicker = false
    @State private var pagos: [Pago] = []
    @State private var selectedPago: Pago?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Pagos")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showYearPicker = true }) {
                        Text(String(selectedYear))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
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
                                Text("Ubicación")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Text(selectedUbicacion)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 40) {
                                Text("FOLIO")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("FECHA")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("UBICACIÓN")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(40)
                            } else if pagos.isEmpty {
                                Text("No se encontraron pagos para este periodo")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(40)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(pagos) { pago in
                                        Button(action: { selectedPago = pago }) {
                                            PagoRow(pago: pago)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                    }
                    .padding(16)
                }
            }
            .background(Color.appBackground)
            .navigationBarBackButtonHidden()

            if showYearPicker {
                YearPickerOverlay(
                    selectedYear: selectedYear,
                    onCancel: { showYearPicker = false },
                    onAccept: { year in
                        selectedYear = year
                        showYearPicker = false
                        loadPagosData()
                    }
                )
            }
        }
        .onAppear {
            loadPagosData()
        }
        .sheet(item: $selectedPago) { pago in
            ComprobantePagoSheet(pago: pago)
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
        }
    }

    private func loadPagosData() {
        Task {
            await MainActor.run { isLoading = true }
            let params = ["ano": String(selectedYear)]
            if let data = await authService.fetchCarouselData(endpoint: "pagos/anual", params: params) {
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("📄 Pagos Data: \(jsonStr.prefix(500))")
                }
                do {
                    let response = try JSONDecoder().decode(PagosResponse.self, from: data)
                    await MainActor.run {
                        self.pagos = response.data ?? []
                        isLoading = false
                    }
                } catch {
                    print("❌ Error decodificando pagos: \(error)")
                    await MainActor.run {
                        self.pagos = []
                        isLoading = false
                    }
                }
            } else {
                print("❌ No data received from pagos/anual")
                await MainActor.run {
                    self.pagos = []
                    isLoading = false
                }
            }
        }
    }
}

struct Pago: Codable, Identifiable {
    let id: Int
    let folio_pago: String?
    let fecha: String?
    let ano: Int?
    let monto: FlexibleNumber?
    let descuento: FlexibleNumber?
    let descripcion: String?
    let referencia_pago: String?
    let referencia_banco: String?
    let validado: Int?
    let status: Int?
    let validado_text: String?
    let concepto: PagoConcepto?
    let ubicacion: PagoUbicacion?
    let metodo_pago: PagoMetodo?
    let user_realiza_pago: PagoUsuario?
    let user_recibe_pago: PagoUsuario?

    var montoValor: Double { monto?.value ?? 0 }
    var descuentoValor: Double { descuento?.value ?? 0 }
}

/// La API a veces devuelve montos como número JSON y a veces como texto (ej. "1500.00").
/// Este wrapper acepta ambos para que un cambio de formato del backend no rompa el decode.
struct FlexibleNumber: Codable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self), let parsed = Double(stringValue) {
            value = parsed
        } else {
            value = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct PagoConcepto: Codable {
    let descripcion: String?
}

struct PagoUbicacion: Codable {
    let direccion: String?
}

struct PagoMetodo: Codable {
    let descripcion: String?
}

struct PagoUsuario: Codable {
    let nombre_completo: String?
    let email: String?
}

struct PagosResponse: Codable {
    let success: Bool?
    let total: Int?
    let data: [Pago]?
}

struct PagoRow: View {
    let pago: Pago

    private var colorEstatus: Color {
        switch pago.validado {
        case 1:
            return Color.statusSuccess
        case 0:
            return Color.statusWarning
        default:
            return Color.gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(pago.folio_pago ?? "N/A")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(pago.fecha ?? "N/A")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(pago.ubicacion?.direccion ?? "N/A")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(colorEstatus)
        .cornerRadius(8)
    }
}

struct YearPickerOverlay: View {
    let selectedYear: Int
    let onCancel: () -> Void
    let onAccept: (Int) -> Void

    @State private var tempYear: Int

    private let years: [Int]

    init(selectedYear: Int, onCancel: @escaping () -> Void, onAccept: @escaping (Int) -> Void) {
        self.selectedYear = selectedYear
        self.onCancel = onCancel
        self.onAccept = onAccept
        _tempYear = State(initialValue: selectedYear)
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array((currentYear - 10)...currentYear).reversed()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(alignment: .leading, spacing: 16) {
                Text("Seleccionar Año")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                Picker("Año", selection: $tempYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year))
                            .font(.system(size: 20, weight: year == tempYear ? .bold : .regular))
                            .foregroundColor(.primary)
                            .tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .clipped()

                HStack {
                    Spacer()
                    Button(action: onCancel) {
                        Text("CANCELAR")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    Button(action: { onAccept(tempYear) }) {
                        Text("ACEPTAR")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(Color.cardBackground)
            .cornerRadius(4)
            .frame(maxWidth: 320)
            .padding(.horizontal, 32)
        }
    }
}

struct ComprobantePagoSheet: View {
    @Environment(\.dismiss) var dismiss
    let pago: Pago

    private var total: Double {
        pago.montoValor - pago.descuentoValor
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Comprobante de pago")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 16) {
                            Image("logoApp")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 56, height: 56)
                                .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Comprobante de pago")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                                Text(pago.folio_pago ?? "N/A")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.red)
                                Text("Fecha de pago: \(pago.fecha ?? "N/A")")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pagado por:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(pago.user_realiza_pago?.nombre_completo ?? "N/A")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                if let direccion = pago.ubicacion?.direccion {
                                    Text(direccion)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                if let email = pago.user_realiza_pago?.email {
                                    Text(email)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Validado por:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(pago.user_recibe_pago?.nombre_completo ?? "N/A")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                if let email = pago.user_recibe_pago?.email {
                                    Text(email)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Método de pago:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(pago.metodo_pago?.descripcion ?? "N/A")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Referencia:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(pago.referencia_pago ?? pago.referencia_banco ?? "N/A")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Descripción:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text((pago.descripcion?.isEmpty == false ? pago.descripcion! : "—"))
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 0) {
                            HStack {
                                Text("DESCRIPCIÓN")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("AÑO")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("MONTO")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color(red: 0.05, green: 0.2, blue: 0.35))

                            HStack {
                                Text(pago.concepto?.descripcion ?? "N/A")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(pago.ano.map { String($0) } ?? "N/A")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("$\(String(format: "%.2f", pago.montoValor))")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(Color.gray.opacity(0.15))
                        }
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                        Text("Total: $\(String(format: "%.2f", total)) MXN")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
                .padding(16)
            }
        }
        .background(Color.appBackground)
    }
}

#Preview {
    PagosView()
        .environmentObject(AuthService(mockData: true))
}
