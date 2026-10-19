# AGENTS.md

Instrucciones para agentes que trabajan en este repositorio. Consultar README y configuración para el detalle; este archivo no autoriza publicación ni cambios fuera de la tarea.

## Propósito del proyecto

Gestión de ingresos/gastos, presupuestos, metas, deudas y reportes, con autenticación, captura asistida, sincronización y seguridad local. Quick Finance contiene persistencia offline y sincronización; no mezclar contratos legacy con el modelo nuevo sin mapper.

## Stack y plataformas

flutter_bloc, Provider, GetIt, Hive/Hive Flutter, SharedPreferences, Firebase Auth/Firestore/Storage/Analytics/Crashlytics/Remote Config/Messaging/App Check/AI y RevenueCat.

Requisito Dart declarado: `">=3.7.0 <4.0.0"` en `pubspec.yaml`; los rangos de dependencias no prueban la versión resuelta. No hay `.fvmrc` versionado; contrastar SDK con README y pubspec.

Proyectos de plataforma presentes: android, ios, linux, macos, web, windows. Esto no garantiza que todos los plugins funcionen en cada plataforma.

## Estructura del repositorio

`lib/core/` contiene configuración, seguridad, servicios y mappers; `lib/features/` módulos con data/domain/presentation. Quick Finance contiene modelos Hive y cola de sincronización. DI en `lib/injection_container.dart` y `lib/utils/injection_container.dart`: revisar cuál usa el flujo. `test/features/` y `test/core/` contienen pruebas.

## Preparación y comandos

Requisitos: SDK Flutter compatible con pubspec. Android necesita su toolchain/JDK de Gradle; iOS requiere macOS/Xcode y la gestión de dependencias del proyecto. Integraciones Firebase requieren configuración de desarrollo existente.

| Acción | Comando desde la raíz |
| --- | --- |
| Dependencias | `flutter pub get` |
| Ejecutar | `flutter run -d <dispositivo>` |
| Formato | `dart format lib test` |
| Análisis | `flutter analyze` |
| Pruebas | `flutter test` |
| Build Android de comprobación | `flutter build apk --debug` |

`dart run build_runner build --delete-conflicting-outputs` al cambiar modelos (con prefijo `fvm` si ese es el entorno configurado). Para desarrollo: `flutter run --dart-define=APP_ENV=development`.

Los comandos fueron contrastados con dependencias, documentación/configuración y suites presentes; no ejecutados al redactar este archivo. Build de distribución requiere firma/configuración adicional; no sustituye despliegue.

## Arquitectura y convenciones

Mantener contratos domain y BLoC existentes, Either/failures donde se usan y repositorios como acceso a datos. Conservar IDs/typeId/campos Hive y compatibilidad del LegacyTransactionMapper; consultar `DATA_COMPATIBILITY_GUIDE.md`. Regenerar archivos `.g.dart` al cambiar modelos, no editarlos a mano. Evitar duplicar movimientos en captura automática, enlaces de metas/deudas o reintentos de sync.

Conservar nombres y convenciones del módulo: Dart snake_case para archivos, UpperCamelCase para tipos y lowerCamelCase para miembros. No renombrar APIs/campos persistidos incidentalmente; respetar lints de analysis_options.yaml.

## Experiencia de usuario

Mostrar estado pendiente/error de sincronización y conservar operaciones locales ante desconexión. Validar importes, moneda, fechas y entradas vacías; probar saldos después de editar/eliminar. No ocultar errores detrás de resultados financieros inventados. Reutilizar componentes, tema y biometría existentes.

En el flujo afectado, contemplar carga, vacío, éxito y error; dar feedback claro, conservar entradas/datos ante fallos y permitir recuperación. Reutilizar componentes visuales; revisar semántica, foco, contraste y escalado de texto.

## Seguridad y datos

No incluir secretos, credenciales ni datos personales en código, documentación o logs. Usar configuración de entorno existente, validar entradas y manejar fallos de servicios. Respetar autenticación, autorización y permisos. No ejecutar operaciones destructivas sobre datos sin autorización explícita.

Preservar cifrado Hive y almacenamiento seguro de claves/sesión. Aislar datos por usuario al cambiar cuenta o cerrar sesión. No registrar extractos, recibos, tokens ni montos privados. `AppConfig.isProduction` también depende de kReleaseMode: release puede usar producción aun con APP_ENV=development; evitar escrituras reales en pruebas.

## Pruebas y validación

Ejecutar pruebas afectadas en quick_finance, auto_capture y transaction_linking. Validar parsers/mappers legacy, cola offline, reconciliación sin duplicados, edición/borrado, login/logout y limpieza por usuario. Cambios de biometría/captura nativa requieren dispositivo; usar mocks existentes para servicios.

Ejecutar análisis y pruebas relevantes según el cambio; compilar solo plataformas afectadas. Un cambio exclusivamente documental requiere revisar rutas, comandos, alcance y diff, sin pruebas artificiales que repliquen el texto. No afirmar que una prueba pasó si no se ejecutó.

## Flujo de trabajo del agente

Leer instrucciones aplicables antes de modificar archivos, incluidas las de subdirectorios: su alcance local se respeta. Las instrucciones explícitas del usuario prevalecen.

1. Revisar estado del trabajo y comprender el flujo afectado antes de implementar.
2. Hacer cambios acotados al objetivo; respetar cambios existentes del usuario y evitar refactorizaciones ajenas.
3. Reutilizar componentes y dependencias disponibles; justificar dependencias nuevas.
4. Actualizar documentación si cambia comportamiento o configuración.
5. Ejecutar verificaciones pertinentes y comunicar resultados y pendientes con su motivo.
6. No hacer commits, push o despliegues salvo solicitud o autorización previa del usuario. Esta regla prevalece sobre recomendaciones de commit automático en guías antiguas.

Respetar README: ramas desde `develop` y PR a `develop`.

No activar workflows de publicación ni scripts de release como comprobación rutinaria.

## Criterios de finalización

La tarea cumple el comportamiento solicitado, contempla errores/estados relevantes, mantiene convenciones y pasa las verificaciones aplicables que puedan ejecutarse. Comunicar archivos modificados, resultados reales y cualquier validación pendiente con su motivo.

## Limitaciones y aspectos por confirmar

README prescribe FVM/Flutter 3.44.0, pero no hay `.fvmrc` versionado en el árbol revisado: confirmar SDK local antes de resolver dependencias. Los scaffolds web/escritorio no garantizan compatibilidad de todos los plugins.
