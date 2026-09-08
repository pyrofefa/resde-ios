import SwiftUI
import Combine

enum ConceptoReporte {
    case ingresos
    case egresos
}

@MainActor
class ReportesViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var resumenFinanciero: BalanceMensualData?
    @Published var totalesGrafica: TotalesGraficaData?
    @Published var barrasIngresos: [BarraConcepto] = []
    @Published var barrasEgresos: [BarraConcepto] = []
    @Published var tendenciaIngresos: [PuntoTendencia] = []
    @Published var tendenciaEgresos: [PuntoTendencia] = []
    @Published var isLoading = true
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var conceptoSeleccionado: ConceptoReporte = .ingresos
    @Published var tablaIngresos: [MovimientoDetalle] = []
    @Published var tablaEgresos: [MovimientoDetalle] = []
    @Published var isLoadingDetalle = false

    private let authService = AuthService(mockData: false)

    init() {
        authService.loadTokenFromKeychain()
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM/yyyy"
        return formatter.string(from: selectedDate).uppercased()
    }

    func loadReportes() async {
        isLoading = true
        showError = false

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fechaParam = dateFormatter.string(from: selectedDate)

        async let balance = fetchReporte(endpoint: "balance-mensual", fecha: fechaParam)
        async let grafica = fetchReporte(endpoint: "totales-grafica-mes", fecha: fechaParam)
        async let barras = fetchReporte(endpoint: "datos-grafica-barras", fecha: fechaParam)
        async let tendencia = fetchReporte(endpoint: "tendencia-financiera-mes", fecha: fechaParam)

        let (balanceData, graficaData, barrasData, tendenciaData) = await (balance, grafica, barras, tendencia)

        var huboError = false

        resumenFinanciero = nil
        totalesGrafica = nil
        barrasIngresos = []
        barrasEgresos = []
        tendenciaIngresos = []
        tendenciaEgresos = []

        if let balanceData = balanceData {
            do {
                let response = try JSONDecoder().decode(BalanceMensualResponse.self, from: balanceData)
                resumenFinanciero = response.data
            } catch {
                print("❌ Error decodificando balance: \(error)")
                huboError = true
            }
        }

        if let graficaData = graficaData {
            do {
                let response = try JSONDecoder().decode(TotalesGraficaResponse.self, from: graficaData)
                totalesGrafica = response.data
            } catch {
                print("❌ Error decodificando totales de gráfica: \(error)")
            }
        }

        if let barrasData = barrasData {
            do {
                let response = try JSONDecoder().decode(DatosGraficaBarrasResponse.self, from: barrasData)
                barrasIngresos = response.data?.barras_ingresos ?? []
                barrasEgresos = response.data?.barras_egresos ?? []
            } catch {
                print("❌ Error decodificando gráfica de barras: \(error)")
            }
        }

        if let tendenciaData = tendenciaData {
            do {
                let response = try JSONDecoder().decode(TendenciaFinancieraResponse.self, from: tendenciaData)
                tendenciaIngresos = response.data?.ingresos ?? []
                tendenciaEgresos = response.data?.egresos ?? []
            } catch {
                print("❌ Error decodificando tendencia financiera: \(error)")
            }
        }

        if huboError {
            errorMessage = "Error al cargar el reporte"
            showError = true
        }

        isLoading = false
    }

    func loadDetalleMovimientos() async {
        isLoadingDetalle = true

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fechaParam = dateFormatter.string(from: selectedDate)

        if let data = await fetchReporte(endpoint: "totales-ingresos-egresos", fecha: fechaParam) {
            do {
                let response = try JSONDecoder().decode(TotalesIngresosEgresosResponse.self, from: data)
                tablaIngresos = response.data?.tabla_ingresos ?? []
                tablaEgresos = response.data?.tabla_egresos ?? []
            } catch {
                print("❌ Error decodificando detalle de movimientos: \(error)")
                tablaIngresos = []
                tablaEgresos = []
            }
        } else {
            tablaIngresos = []
            tablaEgresos = []
        }

        isLoadingDetalle = false
    }

    private func fetchReporte(endpoint: String, fecha: String) async -> Data? {
        guard let url = URL(string: "https://resde.aseenti.com.mx/api/v1/reportes/\(endpoint)?fecha=\(fecha)") else {
            return nil
        }

        var request = URLRequest(url: url)
        if let token = authService.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            checkTokenInvalido(response)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403 {
                return nil
            }
            return data
        } catch {
            print("❌ Error obteniendo \(endpoint): \(error)")
            return nil
        }
    }
}

// MARK: - Resumen Financiero (balance-mensual)

struct RangoConsultado: Codable {
    let desde: String?
    let hasta: String?
}

struct BalanceMensualData: Codable {
    let total_ingresos_mes: String
    let total_egresos_mes: String
    let balance_neto: String
    let saldo_inicial_mes: String?
    let saldo_final: String?
    let rango_consultado: RangoConsultado?

    var ingresosValor: Double { Double(total_ingresos_mes) ?? 0 }
    var egresosValor: Double { Double(total_egresos_mes) ?? 0 }
    var balanceValor: Double { Double(balance_neto) ?? 0 }
}

struct BalanceMensualResponse: Codable {
    let success: Bool?
    let data: BalanceMensualData?
    let message: String?
}

// MARK: - Totales para gráfica de pastel (totales-grafica-mes)

struct TotalesGraficaData: Codable {
    let total_ingresos: FlexibleNumber?
    let total_egresos: FlexibleNumber?

    var ingresosValor: Double { total_ingresos?.value ?? 0 }
    var egresosValor: Double { total_egresos?.value ?? 0 }
}

struct TotalesGraficaResponse: Codable {
    let success: Bool?
    let data: TotalesGraficaData?
    let message: String?
}

// MARK: - Desglose por conceptos (datos-grafica-barras)

struct BarraConcepto: Codable, Identifiable {
    var id: String { concepto ?? UUID().uuidString }
    let concepto: String?
    let total_pagos: Int?
    let total_egresos: Int?
    let total_monto: FlexibleNumber?

    var montoValor: Double { total_monto?.value ?? 0 }
    var cantidad: Int { total_pagos ?? total_egresos ?? 0 }
}

struct DatosGraficaBarrasData: Codable {
    let barras_ingresos: [BarraConcepto]?
    let barras_egresos: [BarraConcepto]?
}

struct DatosGraficaBarrasResponse: Codable {
    let success: Bool?
    let data: DatosGraficaBarrasData?
    let message: String?
}

// MARK: - Tendencia financiera diaria (tendencia-financiera-mes)

struct PuntoTendencia: Codable, Identifiable {
    var id: String { fecha ?? UUID().uuidString }
    let fecha: String?
    let monto: FlexibleNumber?

    var montoValor: Double { monto?.value ?? 0 }

    var fechaDate: Date? {
        guard let fecha = fecha else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: fecha)
    }
}

struct TendenciaFinancieraData: Codable {
    let ingresos: [PuntoTendencia]?
    let egresos: [PuntoTendencia]?
}

struct TendenciaFinancieraResponse: Codable {
    let success: Bool?
    let data: TendenciaFinancieraData?
    let message: String?
}

// MARK: - Detalle de movimientos (totales-ingresos-egresos)

struct MovimientoDetalle: Decodable, Identifiable {
    var id: String { folio ?? UUID().uuidString }
    let folio: String?
    let fecha: String?
    let concepto: String?
    let monto: FlexibleNumber?
    let descuento: FlexibleNumber?
    let forma_metodo_pago: String?
    let referencia_banco: String?
    let tipo: String?

    var montoValor: Double { monto?.value ?? 0 }
    var descuentoValor: Double { descuento?.value ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case folio, fecha, monto, descuento, tipo
        case forma_metodo_pago
        case referencia_banco
        case concepto
        case concepto_s
        case conceptos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        folio = try? container.decode(String.self, forKey: .folio)
        fecha = try? container.decode(String.self, forKey: .fecha)
        monto = try? container.decode(FlexibleNumber.self, forKey: .monto)
        descuento = try? container.decode(FlexibleNumber.self, forKey: .descuento)
        forma_metodo_pago = try? container.decode(String.self, forKey: .forma_metodo_pago)
        referencia_banco = try? container.decode(String.self, forKey: .referencia_banco)
        tipo = try? container.decode(String.self, forKey: .tipo)
        concepto = (try? container.decode(String.self, forKey: .concepto))
            ?? (try? container.decode(String.self, forKey: .concepto_s))
            ?? (try? container.decode(String.self, forKey: .conceptos))
    }
}

struct TotalesIngresosEgresosData: Decodable {
    let tabla_ingresos: [MovimientoDetalle]?
    let tabla_egresos: [MovimientoDetalle]?
}

struct TotalesIngresosEgresosResponse: Decodable {
    let success: Bool?
    let data: TotalesIngresosEgresosData?
    let message: String?
}
