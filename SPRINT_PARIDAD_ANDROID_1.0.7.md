# Sprint: Paridad iOS ↔ Android 1.0.7

**Referencia:** `ESPECIFICACION_FUNCIONAL_IOS.pdf` + commit `6ca5919` del repo Android (v1.0.7).
**Duración sugerida:** 2 semanas · **Base iOS:** 1.0.4 (build 4), rama `develop`.
**Estimación:** puntos de historia (1 ≈ medio día).

## Objetivo del sprint
Cerrar la brecha funcional con Android 1.0.7: permisos correctos, módulo Mascotas completo (CRUD + QR), Mapa Residencial, descripción en códigos de reunión y los comportamientos pendientes de la especificación.

## Definición de terminado (DoD, aplica a todas las historias)
- Compila sin warnings nuevos; target iOS 17+.
- Mensajes, textos y payloads coinciden con la especificación (no se inventan textos).
- Errores de red/servidor muestran diálogo/toast, nunca pantalla en blanco ni crash.
- 401 sigue llevando al Login con el mensaje del servidor.
- Probado en un iPhone físico con un usuario normal y con un súper admin.
- PR a `develop` con descripción de cambios.

---

## Resumen del backlog

| # | Historia | Prioridad | Pts |
|---|---|---|---|
| H1 | Permisos de módulos alineados a Android | Alta | 2 |
| H2 | Gating del resumen del Home y del botón de apertura | Alta | 3 |
| H3 | Descripción en código de reunión + detalle/compartir | Alta | 3 |
| H4 | Mascotas: listado, alta, edición y baja | Alta | 8 |
| H5 | Identificar mascota por QR | Media | 5 |
| H6 | Mapa Residencial | Media | 8 |
| H7 | Reporte no publicado | Media | 2 |
| H8 | Comprobante de pago: compartir como imagen | Baja | 3 |
| H9 | Apertura de pluma: animaciones y errores | Baja | 3 |
| H10 | Login, sesión y avisos (ajustes menores) | Baja | 2 |
| | **Total** | | **39** |

Si el equipo no alcanza: H1–H5 son el núcleo (21 pts); H6 es el siguiente corte; H7–H10 son relleno.

---

## H1 · Permisos de módulos alineados a Android
**Contexto:** Android cambió permisos. iOS usa los anteriores (`pago.create`, sin permiso en Claves/Historial).

| Módulo | iOS hoy | Debe ser |
|---|---|---|
| Pagos | `pago.create` | `pago.manage` |
| Mensualidades | `pago.create` | `pago.manage` |
| Claves de acceso | ninguno | `acceso.manage` |
| Historial de accesos | ninguno | `acceso.history` |
| Mapa Residencial (nuevo) | — | `reporte.mapa` |
| Identificar Mascota (nuevo) | — | ninguno (público) |
| Reglamentos | ninguno | ninguno (público) |

**Criterios de aceptación**
1. Dado un usuario con solo `pago.manage`, ve Pagos y Mensualidades y no ve Claves ni Historial.
2. Dado un usuario sin `acceso.manage`, no aparece Claves de acceso; sin `acceso.history`, no aparece Historial.
3. Un súper admin ve todos los módulos sin importar `permissions`.
4. Una categoría sin módulos visibles no dibuja su encabezado.
5. Reglamentos e Identificar Mascota se ven para cualquier usuario.
6. Al cambiar permisos en el servidor, el Home se actualiza tras el aviso de permisos (ya existente).

## H2 · Gating del resumen del Home y del botón de apertura
**Criterios de aceptación**
1. Sin `reporte.resumen` (y no súper admin): no se muestran el carrusel de tarjetas, el resumen financiero ni el panorama anual, ni sus indicadores de carga; solo los módulos.
2. Con `reporte.resumen` o súper admin: se muestran los tres bloques con el indicador de carga con logo.
3. El botón de apertura aparece solo con `acceso.open`, `acceso.create` o súper admin.
4. En el sheet de apertura: con ambos permisos hay dos pestañas ("Abrir Portón" y "Generar Código"); con uno solo no hay pestañas y se abre directo ese contenido.
5. Sin ninguno de los dos permisos: se muestra "No tienes permisos para realizar estas acciones" y el sheet se cierra. Con solo generar: "No tienes permisos para generar códigos de acceso".
6. El botón de apertura no se muestra mientras hay un módulo abierto, solo en el Home.

## H3 · Descripción en código de reunión
**Criterios de aceptación**
1. Al elegir "Reunión" aparece un campo multilínea opcional con contador `n/100` y límite de 100 caracteres. En Visita y Paquetería no aparece.
2. El payload de `POST claves-acceso` incluye `descripcion` solo si es reunión y no está vacía (con `trim`); si está vacía no se envía el campo.
3. Si hay descripción, el detalle del token muestra `Evento/Reunión: {nombre}` y debajo `💬 {descripcion}`; si no, `Visitante: {nombre}`.
4. La vigencia muestra `Ubicación: {ubicacionNombre}` (si existe) y `Válido hasta: {fechaExpiracionFormato}` (por defecto "24 horas").
5. El mensaje de compartir cambia si hay descripción: `¡Hola! Te comparto la invitación para {nombre} en {residencial}: 💬 "{descripcion}" …`; sin descripción mantiene el texto de saludo con el nombre.
6. El modelo de clave decodifica `descripcion` opcional sin romper claves antiguas.
7. Los demás campos del payload no cambian (reunión: `limite_usos` 20, `fecha_expiracion` `yyyy-MM-dd`; visita/paquetería sin `fecha_expiracion`).

## H4 · Mascotas: listado, alta, edición y baja
**Contexto:** iOS usa el esquema viejo de contador (`mascotas/get` y `mascotas/update`). Android usa CRUD completo.

**Criterios de aceptación**
1. Listado: `GET mascotas/lista?ubicacion_id=` con la ubicación compartida del Home; cada fila muestra foto (o huella por defecto), nombre y chip de especie. Contador `(N)`.
2. Estado vacío cuando no hay mascotas; pull-to-refresh recarga.
3. Alta: especies desde `GET mascotas/especies`; nombre y especie obligatorios; foto opcional por cámara o galería.
4. El alta envía `multipart/form-data` a `POST mascotas/registrar` con `ubicacion_id`, `nombre`, `especie_id` y `foto` (JPEG, calidad 0.8) si hay foto.
5. Edición al tocar la tarjeta: `POST mascotas/editar` con además `uuid` e `id`; `eliminar_foto = "1"` solo si se marcó "Quitar foto".
6. Baja: confirmación "¿Estás seguro de dar de baja a {nombre}?"; `POST mascotas/deactivate` con `{ "uuid": "…" }`; al éxito se quita de la lista y baja el contador.
7. Errores de red o de servidor se muestran con el mensaje del servidor; no se pierde lo capturado en el formulario.
8. Info.plist con textos de cámara y fotos que mencionen mascotas (hoy mencionan quejas).
9. Se retira el flujo y los modelos del contador viejo.

## H5 · Identificar mascota por QR
**Criterios de aceptación**
1. Módulo "Identificar Mascota" visible para todo usuario (categoría Mi Hogar).
2. Al abrir pide permiso de cámara; si se niega, explica cómo habilitarlo en Ajustes.
3. Al leer un QR llama `GET mascotas/qr?codigo={codigo}` una sola vez por lectura.
4. Éxito: muestra nombre, especie, dirección del domicilio, nombre del residencial y la foto (cargada con encabezado `Authorization`).
5. No encontrada: aviso "No se encontró ninguna mascota activa con ese código QR." con botón "Intentar de nuevo" que reanuda el escaneo.
6. Sin conexión: mensaje de error, sin crash y sin escaneos repetidos.

## H6 · Mapa Residencial
**Criterios de aceptación**
1. Módulo "Mapa Residencial" visible con `reporte.mapa` o súper admin, en Pagos y Finanzas.
2. `GET ubicaciones/mapa?anio=` (sin `anio` la primera vez; el backend devuelve el año activo).
3. Mapa satelital/híbrido con controles de zoom; al cargar ajusta la cámara para englobar todas las casas válidas (con margen).
4. Un pin en forma de casa por lote con el número (`numero`), con color según el semáforo del mes: `al_corriente` #16A34A, `parcial` #EAB308, `convenio` #9333EA, `adeudo` o desconocido #EF4444.
5. Las ubicaciones sin `lat`/`lng` válidos no dibujan pin y no rompen el mapa.
6. La vivienda propia (`es_propia == true`) se distingue (borde dorado u otro distintivo).
7. Leyenda superior con contadores del mes: "Al corriente: N", "Pago parcial: N", "Con adeudo: N", "Convenio: N".
8. Selector de año con `anios_disponibles`; cambiar de año recarga desde la API.
9. Flechas anterior/siguiente para el mes: cambian leyenda y pines sin llamar a la API (usa caché del año cargado).
10. Botón "Actualizar" fuerza la recarga del año seleccionado.
11. Estados de carga con el logo y de error con reintento.

## H7 · Reporte no publicado
**Criterios de aceptación**
1. Si cualquiera de los endpoints de reportes responde `code == "REPORTE_NO_PUBLICADO"`, no se muestra error genérico.
2. Las cifras de balance quedan en `$0.00` y se muestra el mensaje oficial del servidor.
3. Se ocultan ingresos, egresos, balance neto, saldos inicial y final y "Ver más movimientos".
4. Las tres gráficas se ocultan y en su lugar se muestra el mensaje de sin datos.
5. Al cambiar a un mes publicado, la pantalla vuelve a la normalidad.

## H8 · Comprobante de pago: compartir como imagen
**Contexto:** iOS tiene el comprobante pero no el botón de compartir/imprimir.

**Criterios de aceptación**
1. El comprobante muestra logo, folio, fecha, residente, ubicación, correo, receptor, método, referencia, concepto y monto con formato `$12,450.00`.
2. El botón compartir renderiza el comprobante como imagen PNG (`comprobante_{folio}.png`) y abre la hoja de compartir del sistema.
3. La imagen respeta modo claro y oscuro (se renderiza con fondo propio).
4. Si falla el render, se muestra un error y la pantalla sigue usable.

## H9 · Apertura de pluma: animaciones y errores
**Criterios de aceptación**
1. Toque simple: aviso "Mantén presionado el círculo unos segundos para abrir" y pulso breve.
2. Mantener presionado: deshabilita el círculo, baja la opacidad a 0.7, muestra el spinner y un pulso continuo mientras responde.
3. Antes de llamar, revisa conectividad; sin internet muestra "No cuentas con conexión a internet en este momento." en un diálogo.
4. Éxito (`status == success` u `ok`): círculo verde, texto "¡ABIERTO!", rebote 1.15× → 1.0×, y cierra el sheet a los 1.5 s.
5. Error: diálogo con el mensaje del servidor; el círculo vuelve a su estado normal y reutilizable.
6. El body envía `ubicacion_id`, `dispositivo` (ej. "Apple iPhone 15") e `ip`.

## H10 · Login, sesión y avisos (ajustes menores)
**Criterios de aceptación**
1. Login: sin conexión, correo vacío y contraseña vacía muestran los tres mensajes de la especificación ("No cuentas con conexión a internet en este momento.", "Por favor ingresa un correo electrónico válido.", "Por favor ingresa tu contraseña.").
2. Error de login: usa `msj` o `message` del servidor; fallback "Credenciales incorrectas.".
3. Un 401 usa `message` o `msj`; fallback "Su sesión ha expirado o fue iniciada en otro dispositivo." y regresa al Login con ese mensaje.
4. El aviso de "permisos actualizados" pasa a un sheet inferior con botón "Entendido"; al cerrarlo recarga cabecera, módulos y resumen.
5. El token de push no cambia: se mantiene `plataforma: "ios"`, `modelo_dispositivo`, `app_version` (ver riesgos).

---

## Riesgos y dependencias
- **Backend:** confirmar que `mascotas/lista`, `mascotas/especies`, `mascotas/registrar`, `mascotas/editar`, `mascotas/qr` y `ubicaciones/mapa` están en producción y devuelven lo descrito.
- **Discrepancia en la especificación:** sección 1.3 dice que el body de `devices/token` es `{token, device_type}`, pero el código Android real manda `{token, plataforma, modelo_dispositivo, app_version}`. iOS ya usa la forma real. Pedir a quien escribió el documento que lo confirme con backend.
- **Versión de referencia:** el PDF dice "1.0.3", pero refleja el código 1.0.7. Si hay conflicto, manda el código Android.
- **Push en iOS:** sigue pendiente la configuración de Apple (Push Notifications en el App ID, perfil nuevo y llave `.p8` en el backend). Probar solo en iPhone físico.
- **Mapa:** requiere MapKit; no necesita llave externa, pero conviene probar con datos reales (muchos pines).
- **Cámara:** H4 y H5 requieren permisos en Info.plist y pruebas en dispositivo; el simulador no tiene cámara.
- **Tiempo:** H4 y H6 son las más grandes; no iniciar H6 si H4 no pasó revisión.

## Orden recomendado
1. H1 y H2 (rápidas, evitan accesos incorrectos).
2. H3.
3. H4 y luego H5.
4. H6.
5. H7–H10 según capacidad.
