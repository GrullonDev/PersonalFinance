# iOS MVP — Release Guide

Branch: `feature/ios-mvp-launch` (desde `feature/mvp-quick-finance`).
Versión objetivo: `1.0.1` (o la próxima que definas en `pubspec.yaml`).
Bundle ID: `com.grullondev.personalFinance`.
Team ID: `7CK75YX2YB`.

Este documento resume los cambios realizados en esta rama y lo que debes
completar manualmente antes de subir a TestFlight / App Store.

---

## Cambios aplicados en esta rama

### 1. `ios/Runner/Info.plist`
- Se eliminó el placeholder literal `tu-client-id-de-google.apps.googleusercontent.com` del valor real de `GIDClientID`. El client ID actual proviene de `GoogleService-Info.plist` (proyecto legacy, ver sección **Acción requerida** abajo).
- Se agregaron las privacy usage descriptions obligatorias:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
  - `NSMicrophoneUsageDescription`
  - `NSFaceIDUsageDescription` (mensaje mejorado)
- Se añadió `ITSAppUsesNonExemptEncryption = false` para evitar la pregunta de export compliance en cada upload.
- Se removieron la clave `google` suelta y la `NSLocalNetworkUsageDescription` con copy "de depuración" (rojizo ante App Review).
- `UISupportedInterfaceOrientations` ahora es portrait-only en iPhone (iPad conserva todas las orientaciones).
- Se declaró `CFBundleLocalizations` con `en` y `es`.
- Se añadió `CFBundleURLName = GoogleSignIn` y el scheme invertido correcto.

### 2. `ios/Runner/Runner.entitlements` (nuevo)
- Entitlement `com.apple.developer.applesignin = ["Default"]` para cumplir el requisito de Apple que obliga a ofrecer **Sign in with Apple** cuando hay login de terceros (Google).

### 3. `ios/Runner.xcodeproj/project.pbxproj`
- Se referenció `Runner.entitlements` en las tres build configurations del target `Runner` (Debug, Release, Profile) vía `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;`.
- Se agregó el archivo al `PBXFileReference` y al grupo `Runner` para que aparezca en Xcode.

### 4. `ios/Runner/AppDelegate.swift`
- Patrón estándar y estable de Flutter: `FlutterAppDelegate` + registro directo de plugins en `didFinishLaunchingWithOptions` con `GeneratedPluginRegistrant.register(with: self)`. Compatible con cualquier versión de Flutter en stable.
- Se añadió override defensivo de `application(_:open:options:)` para reenviar los callbacks OAuth (Google Sign-In) a los plugins.
- **NOTA histórica:** se intentó usar el patrón `FlutterImplicitEngineDelegate` + `UIApplicationSceneManifest` con `FlutterSceneDelegate` (Flutter 3.27+/preview). Cuando el SDK linkeado no expone `FlutterSceneDelegate` como clase Objective-C, iOS no instancia ninguna escena y el resultado es un launch screen blanco eterno **sin ningún log de Flutter** — exactamente el síntoma que se diagnosticó. El rollback al patrón clásico resolvió ese white screen.

### 5. `lib/main.dart`
- Ahora usa `MyApp` (lib/utils/app.dart), que incluye el flujo completo Splash → Onboarding → Auth (email / Google / Apple) → Home.
- Se inicializa **Firebase Crashlytics** y **Firebase Analytics**:
  - Crashlytics solo colecta en release (`!kDebugMode`).
  - `FlutterError.onError` reporta crashes sincrónicos.
  - `PlatformDispatcher.instance.onError` captura asincrónicos.
  - `runZonedGuarded` los envía también a Crashlytics.
  - `FirebaseAnalytics.instance.logAppOpen()` en cada arranque.
- `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` alineado con `Info.plist`.

### 6. `lib/utils/routes/route_switch.dart`
- La ruta `/dashboard` (post-login) ahora renderiza `QuickFinanceHomePage` envuelto en un `BlocProvider<QuickFinanceBloc>` (factory de `GetIt`), para que cada sesión de usuario tenga su Bloc fresco.

### 7. `lib/utils/theme.dart`
- Se añadió `pageTransitionsTheme` con `CupertinoPageTransitionsBuilder` en iOS / macOS y `ZoomPageTransitionsBuilder` en Android, para que las transiciones entre páginas se sientan nativas en cada plataforma.

---

## Acción requerida antes del submit

### 🔴 A) Alinear Firebase con el bundle iOS real
El `firebase_options.dart` apunta a proyecto `personalfinancedev-e972f` con bundle `com.grullondev.personalFinance`, pero el `GoogleService-Info.plist` en la carpeta `ios/Runner/` es del proyecto legacy `personal-finance-7fff1` con bundle `com.jorgegrullon.personalFinance`.

Consecuencias: Firebase Auth opera contra un proyecto, mientras que Google Sign-In nativo usa client IDs del otro → fallará en runtime.

Pasos:
1. Firebase Console → proyecto `personalfinancedev-e972f` → iOS app con bundle `com.grullondev.personalFinance`. Si no existe, crearla.
2. Descarga el nuevo `GoogleService-Info.plist` y reemplaza `ios/Runner/GoogleService-Info.plist`.
3. Copia el `CLIENT_ID` y `REVERSED_CLIENT_ID` del nuevo plist a `Info.plist` (`GIDClientID` y `CFBundleURLSchemes`).
4. Ejecuta `flutterfire configure --project=personalfinancedev-e972f` para regenerar `lib/firebase_options.dart` (opcional, ya está coherente).

### 🔴 B) Apple Developer portal
1. Activa capability **Sign in with Apple** en el App ID `com.grullondev.personalFinance`.
2. Si usas Sign in with Apple desde Android vía web flow, verifica `AuthConfig.appleServiceId = 'com.grullondev.personal_finance'` (Service ID). Si el Service ID real usa `personalFinance` (sin underscore), ajusta `lib/core/config/auth_config.dart`.
3. Regenera el provisioning profile en Xcode (Automatic signing lo hace solo).

### 🟡 C) Regenerar iconos con el logo definitivo
El `flutter_launcher_icons` ya está configurado en `pubspec.yaml`. Después de confirmar el logo final:

```bash
flutter pub get
dart run flutter_launcher_icons
```

### 🟡 D) Launch Screen
La `LaunchScreen.storyboard` actual muestra el logo por defecto de Flutter. Abrir en Xcode y reemplazar `LaunchImage` por el logo de `assets/logo.png` o rediseñar con color primario `#0E8F5B` para mayor polish.

### 🟡 E) Privacy Manifest (`PrivacyInfo.xcprivacy`)
Apple exige `PrivacyInfo.xcprivacy` para apps que usan ciertas APIs (`UserDefaults`, timestamps de archivo, etc.). Los plugins de Firebase y `path_provider` lo requieren. Agrégalo en `ios/Runner/` antes del submit — plantilla ejemplo:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyCollectedDataTypes</key><array/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>CA92.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>C617.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>E174.1</string></array>
    </dict>
    <dict>
      <key>NSPrivacyAccessedAPIType</key>
      <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
      <key>NSPrivacyAccessedAPITypeReasons</key>
      <array><string>35F9.1</string></array>
    </dict>
  </array>
</dict>
</plist>
```

### 🟢 F) Build & verify

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter analyze
flutter test
flutter build ios --release --no-codesign   # smoke test
```

Luego, desde Xcode: `Product → Archive → Distribute App → TestFlight`.

---

## Matriz App Store Review — checklist final

| Ítem                                           | Estado     |
| ---------------------------------------------- | ---------- |
| Sign in with Apple habilitado                  | ✅ (entitlements + pubspec) |
| Privacy usage strings completos                | ✅         |
| Bundle ID y Firebase coherentes                | ⚠️ Pendiente (sección A) |
| GIDClientID real (no placeholder)              | ⚠️ Pendiente (sección A) |
| Export compliance declarado                    | ✅         |
| Portrait-only en iPhone                        | ✅         |
| Crashlytics / Analytics activos                | ✅         |
| Launch screen polish                           | 🟡 Opcional |
| PrivacyInfo.xcprivacy                          | 🟡 Recomendado |
| Logos @1x/@2x/@3x generados                    | ✅ (flutter_launcher_icons) |
