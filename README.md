# CS2 Tracker — Drops, Inventory & Sales

Flutter app (Android / iOS / Desktop) para gestionar cuentas de CS2, drops
semanales, inventario con precios reales del Steam Market, historial de ventas
y estadísticas por cuenta.

## Funcionalidades

- **Multi-cuenta**: registra tus cuentas de CS2 (sólo alias, sin credenciales).
- **Timer semanal**: cuenta atrás hasta el próximo reset (martes 18:00 PST /
  miércoles 01:00 UTC).
- **Estados de drop**: pendiente / obtenido / perdido, con recordatorios
  automáticos 24h antes del reset.
- **Inventario general con precios reales**: cada item consulta el precio
  oficial (mediano) y el icono del Steam Community Market. Caché local de
  2h para precios y 30 días para iconos; throttle anti-429 (700ms entre
  peticiones); recarga forzada real.
- **Cantidades**: añade 5 cajas Kilowatt con un único item; el total y los
  resúmenes multiplican automáticamente.
- **Venta con cantidad**: diálgo "¿cuántas unidades vendiste?" con presets
  1/5/total y chips de cantidad. Registra cada venta como `SaleRecord` con
  snapshot de precio y cuenta.
- **Historial de ventas**: total ingresado en EUR/USD con número de ventas
  y unidades vendidas.
- **Estadísticas por cuenta**: total obtenidos / perdidos / racha actual /
  mejor racha / % de éxito. Se actualizan automáticamente con cada reset
  semanal; "forzar reset manual" NO toca las estadísticas.
- **Backup**: exporta / importa todo (cuentas + inventario + ventas + ajustes)
  a JSON desde Ajustes, vía share sheet de Android.
- **Ordenar inventario**: por fecha (asc/desc), precio (asc/desc) o nombre
  (A-Z / Z-A).

## Tests

```bash
flutter analyze   # 0 issues
flutter test      # 30/30 tests
```

## Build

```bash
flutter pub get
flutter build apk --release    # android
flutter build ios --release    # ios (en macOS)
```

El APK release queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Tech

- Flutter 3.47+, Dart 3.13+
- Riverpod para estado
- Hive para persistencia local
- Dio para HTTP a Steam
- `flutter_local_notifications` + `timezone` para recordatorios
- `path_provider`, `share_plus`, `file_picker` para backup

## Notas

- La app **no** almacena credenciales de Steam, sólo alias de cuentas.
- Los precios son consultados al Steam Community Market (appid 730) y
  cacheados durante 2h para evitar el rate-limit HTTP 429.
- Los items cuya consulta a Steam devuelve `success=false` (p.ej. skins sin
  el sufijo de desgaste) se muestran como `—` y no se guardan con precio 0
  simulado.
