import Foundation
import Network

/// Utilidades de red del dispositivo (equivalente a `Utileria` en Android).
enum Conectividad {
    private final class Estado: @unchecked Sendable {
        var respondido = false
    }

    /// Indica si hay conexión a internet. Si el sistema no responde en 2 s, asume que sí
    /// y deja que la petición falle por su cuenta.
    static func hayInternet() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let cola = DispatchQueue(label: "mx.aseenti.resde.conectividad")
            let estado = Estado()

            monitor.pathUpdateHandler = { path in
                guard !estado.respondido else { return }
                estado.respondido = true
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: cola)

            cola.asyncAfter(deadline: .now() + 2) {
                guard !estado.respondido else { return }
                estado.respondido = true
                monitor.cancel()
                continuation.resume(returning: true)
            }
        }
    }

    /// IPv4 local del dispositivo: Wi-Fi (`en0`), luego datos móviles (`pdp_ip*`), luego cualquier otra.
    static func direccionIPLocal() -> String {
        var lista: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&lista) == 0, let primero = lista else { return "" }
        defer { freeifaddrs(lista) }

        var porInterfaz: [String: String] = [:]
        var actual: UnsafeMutablePointer<ifaddrs>? = primero
        while let puntero = actual {
            let interfaz = puntero.pointee
            if let direccion = interfaz.ifa_addr,
               direccion.pointee.sa_family == UInt8(AF_INET) {
                let nombre = String(cString: interfaz.ifa_name)
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(direccion, socklen_t(direccion.pointee.sa_len),
                               &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    porInterfaz[nombre] = String(cString: host)
                }
            }
            actual = interfaz.ifa_next
        }

        if let wifi = porInterfaz["en0"] { return wifi }
        if let movil = porInterfaz.first(where: { $0.key.hasPrefix("pdp_ip") })?.value { return movil }
        return porInterfaz.first(where: { $0.key != "lo0" })?.value ?? ""
    }
}
