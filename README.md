# Resde

App móvil de gestión residencial para iOS, construida con SwiftUI. Permite a residentes consultar y pagar cuotas, gestionar su información (censo, mascotas, vehículos, cuentas vinculadas), reservar áreas comunes, generar códigos de acceso para visitas y controlar el acceso vehicular/peatonal del residencial.

## Stack

- **SwiftUI** + patrón **MVVM**
- **Swift Charts** para las gráficas de Reportes
- **QuickLook** para visualizar PDFs (Reglamentos)
- Autenticación por token Bearer (Laravel Sanctum) contra un backend REST propio
- Sin dependencias de terceros (no usa CocoaPods / SPM externo)

**Requisitos:** Xcode reciente, iOS 26.2+ como deployment target, Swift 5.

## Estructura del proyecto

```
resde/
├── Models/          # Modelos Codable de las respuestas del API (login, carrusel de Home, etc.)
├── Services/        # AuthService: login, sesión, token, notificaciones de logout/refresh
├── ViewModels/       # Un ViewModel por módulo con estado + llamadas a red
├── Views/
│   ├── HomeView.swift        # Dashboard principal, carrusel, resumen y grid de módulos
│   ├── LoginView.swift
│   ├── Components/           # Sheets/overlays reutilizables entre módulos
│   └── Modules/               # Una vista por módulo (Pagos, Eventos, Quejas, Claves de Acceso, ...)
├── Styles/           # AppColors.swift — tokens de color adaptativos (claro/oscuro) y de estado
└── Assets.xcassets
```

## Módulos implementados

**Pagos y finanzas**
- Pagos (historial, comprobante de pago)
- Mensualidades (resumen anual + detalle mes a mes)
- Reportes (gráficas de ingresos/egresos, comparativos, tendencia)

**Mi hogar**
- Censo, Mascotas, Vehículos
- Cuentas Vinculadas (usuarios secundarios por vivienda)

**Comunidad**
- Eventos (calendario de reservas de áreas comunes)
- Quejas y sugerencias
- Reglamentos (visor de PDF)

**Accesos**
- Apertura remota de pluma (llamada saliente vía Telnyx)
- Generación de claves de acceso temporales para visitas/paquetería/eventos (con envío por WhatsApp)
- Tarjetas de acceso
- Historial de accesos (con filtros por estado y rango de fechas)

## Backend / API

Base URL: `https://resde.aseenti.com.mx/api/v1`

- Autenticación por `POST /login`, token Bearer en cada request subsecuente.
- La sesión se revalida contra `GET /me` al volver a primer plano y periódicamente mientras la app está activa; si el servidor la rechaza, se cierra sesión automáticamente mostrando el motivo exacto.
- Los permisos del usuario (`permissions`) determinan qué módulos se muestran en el grid de Home.

## Cómo correrlo

1. Abrir `resde.xcodeproj` en Xcode.
2. Seleccionar un simulador o dispositivo con iOS 26.2+.
3. Compilar y ejecutar (⌘R). El login requiere credenciales válidas contra el backend real — no hay modo demo/mock en el flujo de producción.

## Ramas y flujo de trabajo

- `main`: rama estable.
- `develop`: rama de desarrollo activo; los cambios se integran a `main` vía Pull Request.
