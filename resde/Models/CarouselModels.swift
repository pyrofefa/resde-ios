//
//  CarouselModels.swift
//  resde
//

import Foundation

struct CarouselData {
    var estadoAdeudos: EstadoAdeudosResponse?
    var censo: CensoResponse?
    var mascotas: MascotasResponse?
    var vehiculos: VehiculosResponse?
    var tarjetas: TarjetasResponse?
    var eventos: EventosResponse?
}

struct EstadoAdeudosResponse: Codable {
    let success: Bool?
    let data: EstadoAdeudosData?
    let message: String?
}

struct EstadoAdeudosData: Codable {
    let cuotaActual: CuotaActual?
    let saldoPendiente: Double?
    let montoValidadoAnio: Double?
    let montoParcial: Double?
    let montoPendiente: Double?
    let montoFaltante: Double?
    let cuotaActualMonto: Double?
    let cuotaSub: String?
    let cuotasValidadasCount: Int?
    let cuotasParcialesCount: Int?
    let cuotasPendientesCount: Int?
    let cuotasFaltantesCount: Int?
    let mesesDetalle: [MesDetalle]?
}

struct CuotaActual: Codable {
    let mes: String?
    let importe: Double?
    let estatus: String?
    let resta: Double?
}

struct MesDetalle: Codable {
    let mes: String?
    let numero: Int?
    let estatus: String?
    let importe: Double?
    let tooltip: String?
}

struct CensoResponse: Codable {
    let success: Bool?
    let numero_residentes: Int?
    let numero_mayores: Int?
    let numero_menores: Int?
    let message: String?
}

struct MascotasResponse: Codable {
    let success: Bool?
    let total_mascotas: Int?
    let message: String?
}

struct VehiculosResponse: Codable {
    let success: Bool?
    let total_vehiculos: Int?
    let message: String?
}

struct TarjetasResponse: Codable {
    let success: Bool?
    let total_tarjetas: Int?
    let message: String?
}

struct EventosResponse: Codable {
    let success: Bool?
    let total_eventos: Int?
    let message: String?
}
