# Personal Finance

[![Flutter](https://img.shields.io/badge/Flutter-3.44.0-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.0-blue.svg?logo=dart)](https://dart.dev)
[![FVM](https://img.shields.io/badge/FVM-enabled-green.svg)](https://fvm.app)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Personal Finance es una aplicacion Flutter para gestionar finanzas personales. Incluye autenticacion, registro de ingresos y gastos, presupuestos, metas, deudas, reportes, notificaciones, sincronizacion con Firebase y seguridad local con biometria e integridad del dispositivo.

## Stack principal

- Flutter `3.44.0` stable
- Dart `3.12.0`
- FVM para administrar la version de Flutter
- Firebase Auth, Firestore, Storage, Analytics, Crashlytics, Remote Config, Messaging y Vertex AI
- BLoC, Provider y GetIt
- Hive y Shared Preferences para persistencia local
- Clean Architecture por features

## Requisitos

Instala y valida estas herramientas antes de levantar el proyecto:

- Git
- FVM
- Android Studio o Xcode, segun la plataforma donde vas a correr la app
- JDK 17 para Android
- CocoaPods para iOS/macOS
- Firebase CLI, recomendado si vas a modificar configuracion de Firebase

Instalacion de FVM:

```bash
dart pub global activate fvm
```

Valida tu entorno:

```bash
fvm flutter doctor
```

## Configuracion inicial

Clona el repositorio y entra al proyecto:

```bash
git clone https://github.com/GrullonDev/personal_finance.git
cd personal_finance
```

Instala la version de Flutter usada por el equipo:

```bash
fvm install 3.44.0
fvm use 3.44.0
```

Obtiene las dependencias:

```bash
fvm flutter pub get
```

Genera codigo cuando cambien modelos con `json_serializable`, Hive u otros builders:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

## Configuracion de Firebase

El proyecto espera los archivos de Firebase por plataforma:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Flutter: `lib/firebase_options.dart`
- Configuracion por ambiente: `lib/core/config/firebase_options_dev.dart` y `lib/core/config/firebase_options_prod.dart`

La app usa `APP_ENV` para resolver el ambiente:

- Desarrollo por defecto: `development`
- Produccion: `production`

Ejecutar en desarrollo:

```bash
fvm flutter run
```

Ejecutar apuntando explicitamente a desarrollo:

```bash
fvm flutter run --dart-define=APP_ENV=development
```

Ejecutar en produccion:

```bash
fvm flutter run --dart-define=APP_ENV=production
```

## Android

Para correr en Android:

```bash
fvm flutter run -d android
```

Para compilar release necesitas `android/key.properties`. Este archivo no debe subirse al repositorio. Debe tener el siguiente formato:

```properties
storePassword=tu_store_password
keyPassword=tu_key_password
keyAlias=tu_alias
storeFile=ruta/al/keystore.jks
```

Builds:

```bash
fvm flutter build apk --release --dart-define=APP_ENV=production
fvm flutter build appbundle --release --dart-define=APP_ENV=production
```

## iOS

Instala pods despues de obtener dependencias:

```bash
cd ios
pod install
cd ..
```

Para correr en iOS:

```bash
fvm flutter run -d ios
```

Build de release:

```bash
fvm flutter build ipa --release --dart-define=APP_ENV=production
```

## Web

Para correr en navegador:

```bash
fvm flutter run -d chrome
```

Build web:

```bash
fvm flutter build web --release --dart-define=APP_ENV=production
```

## Calidad y pruebas

Antes de abrir un PR ejecuta:

```bash
fvm dart format lib test
fvm flutter analyze
fvm flutter test
```

Evita usar `fvm dart format .` despues de compilar la app. Ese comando puede entrar en `build/`, donde Flutter, Gradle y algunos plugins generan archivos temporales que no son parte del codigo fuente. Si ya ocurrio, limpia el proyecto y vuelve a obtener dependencias:

```bash
fvm flutter clean
fvm flutter pub get
```

Si modificaste modelos generados, corre tambien:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

## Flujo de trabajo

La rama base de trabajo es `develop`.

1. Actualiza `develop` antes de empezar:

```bash
git checkout develop
git pull origin develop
```

2. Crea una rama desde `develop`:

```bash
git checkout -b feature/nombre-corto
```

Usa prefijos claros segun el tipo de cambio:

- `feature/` para nuevas funcionalidades
- `fix/` para correcciones
- `hotfix/` para correcciones urgentes
- `chore/` para tareas tecnicas o mantenimiento
- `docs/` para documentacion

3. Haz commits pequenos y descriptivos:

```bash
git add .
git commit -m "feat: describe el cambio"
```

4. Sube tu rama:

```bash
git push origin feature/nombre-corto
```

5. Abre un Pull Request siempre hacia `develop`.

No abras PR directo a `main` o `master` salvo que el equipo lo solicite explicitamente.

## Checklist para Pull Request

- La rama salio desde `develop`
- El PR apunta a `develop`
- `fvm dart format lib test` fue ejecutado
- `fvm flutter analyze` pasa sin errores
- `fvm flutter test` pasa
- Se genero codigo si hubo cambios en modelos o anotaciones
- No se subieron secretos, keystores, certificados ni credenciales privadas
- Se actualizaron documentos si el cambio afecta configuracion o uso

## Estructura del proyecto

```text
lib/
  core/                Configuracion, servicios compartidos, seguridad y utilidades base
  features/            Modulos funcionales de la app
  utils/               Widgets, rutas, helpers y utilidades legacy/compartidas
assets/                Imagenes, iconos y documentos usados por la app
android/               Proyecto Android
ios/                   Proyecto iOS
test/                  Pruebas unitarias y de widgets
```

## Documentacion adicional

- `DATA_COMPATIBILITY_GUIDE.md`: compatibilidad y migracion de datos
- `PRIVACY_POLICY_SETUP.md`: configuracion de politicas de privacidad
- `ios/RELEASE_PLAYBOOK.md`: flujo de release para iOS
- `ios/IOS_MVP_RELEASE_GUIDE.md`: guia de release MVP para iOS

## Autor

Jorge Marroquin - [GitHub @GrullonDev](https://github.com/GrullonDev)

## Licencia

Este proyecto se distribuye bajo la licencia MIT.
