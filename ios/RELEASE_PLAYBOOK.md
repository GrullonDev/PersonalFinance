# 🚀 iOS Release Playbook — Personal Finance

**Bundle ID:** `com.grullondev.personalFinance`
**Team ID:** `7CK75YX2YB`
**Versión actual:** `1.1.4+5` (cambiar en `pubspec.yaml` antes de cada release)
**iOS mínimo:** `16.0`

Este documento te lleva desde tu máquina hasta App Store, en dos modos:

1. **Modo manual** — `Product > Archive` desde Xcode en tu Mac
2. **Modo automático** — Xcode Cloud construyendo y subiendo a TestFlight solo

---

## 0. Cambios que se aplicaron en esta sesión

| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | `version: 1.1.4` → `version: 1.1.4+5` (faltaba el build number) |
| `ios/Runner/Info.plist` | Se añadieron `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryAddUsageDescription` (requeridos por `image_picker` + `google_mlkit_text_recognition`) |
| `ios/Runner/PrivacyInfo.xcprivacy` | **Nuevo** — Privacy Manifest requerido por App Store desde mayo 2024 (UserDefaults, FileTimestamp, DiskSpace, SystemBootTime) |
| `ios/Runner.xcodeproj/project.pbxproj` | Registrado `PrivacyInfo.xcprivacy` en el target Runner (BuildFile + FileReference + Group + Resources phase) |
| `ios/ci_scripts/ci_post_clone.sh` | Refactor: ahora usa canal `stable` por defecto si no defines `FLUTTER_VERSION`, mejor manejo de errores, valida que el tag exista |

---

## 1. Pre-flight checks (correr una vez)

```bash
cd /Volumes/WorkDiskDev/DevTools/flutter_projects/PersonalFinance

# 1. Limpiar todo
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/Flutter/Generated.xcconfig

# 2. Re-resolver
flutter pub get
cd ios && pod install --repo-update && cd ..

# 3. Validar análisis estático
flutter analyze

# 4. Tests
flutter test

# 5. Smoke build de release (sin signing, valida compilación)
flutter build ios --release --no-codesign

# 6. Regenerar íconos (si cambió el logo)
dart run flutter_launcher_icons
```

Si los 6 pasos pasan en verde → estás listo para abrir Xcode.

---

## 2. Configuración de Signing en Xcode (Automatic Signing)

Abre el workspace:

```bash
open ios/Runner.xcworkspace
```

> ⚠️ **Nunca** abras `Runner.xcodeproj` — usa siempre el `.xcworkspace` para que CocoaPods enlace bien.

En Xcode:

1. Selecciona el proyecto **Runner** (raíz del Navigator).
2. Pestaña **Signing & Capabilities** → target **Runner**.
3. Asegura:
   - ☑️ **Automatically manage signing**
   - **Team:** `Jorge Grullon (7CK75YX2YB)` — debe aparecer si tu cuenta Apple Developer está logueada en Xcode → Settings → Accounts
   - **Bundle Identifier:** `com.grullondev.personalFinance`
   - **Provisioning Profile:** Xcode Managed Profile (se genera solo)
   - **Signing Certificate:** Apple Development (debug) / Apple Distribution (release — se crea al hacer Archive)
4. Repite el chequeo para el target **RunnerTests** (mismo Team, signing automático).
5. Capabilities activas (deben verse en la pestaña):
   - **Sign in with Apple** (ya configurado en `Runner.entitlements`)
   - **Push Notifications** (si vas a usar `firebase_messaging` para notifs remotas — recomendado activar ahora)
   - **Background Modes** → `Remote notifications` (si usas push silenciosos)

> 🔴 **Si ves un punto rojo en Signing:** Xcode dirá qué falta. Lo más común:
> - Capability `Sign in with Apple` no está activa en el App ID en developer.apple.com. Ve a https://developer.apple.com/account/resources/identifiers/list → `com.grullondev.personalFinance` → marca el checkbox **Sign In with Apple** → Save → en Xcode pulsa **Try Again**.

---

## 3. Modo MANUAL — Archive desde Xcode

### 3.1 Seleccionar destino

En la barra superior de Xcode, donde dice `iPhone 15 Pro · iOS 17.x`, **cambia a `Any iOS Device (arm64)`**.

> Si no tienes esta opción seleccionada, el menú `Product > Archive` aparece deshabilitado.

### 3.2 Analyze (opcional pero recomendado antes del primer Archive)

`Product > Analyze` (`⇧⌘B`).
- Tarda 2-3 minutos.
- Mostrará warnings de memory leaks, undefined behavior, etc.
- En un proyecto Flutter, casi todo lo que reporte estará en Pods de terceros → puedes ignorarlo. Lo importante es que **no haya errores rojos en tu código Swift de `Runner/`**.

### 3.3 Archive

`Product > Archive` (`⌃⌘A` si está mapeado).

- Tarda 5-15 min la primera vez (compila release, optimiza, firma).
- Al terminar abre el **Organizer** automáticamente con tu archive listado.

### 3.4 Validate App (validación previa al upload)

En el Organizer, con tu archive seleccionado:

1. Click **Validate App**.
2. **Distribution method:** `App Store Connect` → Next.
3. **Destination:** `Upload` → Next.
4. **App Store Connect distribution options:** marca:
   - ☑️ Upload your app's symbols (para que Crashlytics simbolice crashes)
   - ☑️ Manage Version and Build Number (Xcode incrementa el build si chocaste)
5. **Re-sign:** `Automatically manage signing` → Next.
6. Xcode descarga el manifiesto, valida entitlements, permisos, ícono, privacy manifest → muestra **green check** o errores.

Errores comunes y solución:

| Error | Causa | Fix |
|---|---|---|
| `Missing Push Notifications entitlement` | Activaste la capability en Xcode pero el App ID no la tiene | developer.apple.com → App ID → habilita Push Notifications → regenera profile |
| `Invalid Bundle. The bundle does not contain a CFBundleIdentifier` | Ran `pod install` con un Podfile que firma estáticos como bundles | Ya está parcheado en tu Podfile (`CODE_SIGNING_ALLOWED = NO` para bundles) |
| `ITMS-90683: Missing Purpose String` | Falta un `NS*UsageDescription` para un permiso que el código solicita | Agrégalo en `Info.plist` — los 4 más comunes ya están |
| `ITMS-91053: Missing API declaration` | Falta declarar una Required Reason API en `PrivacyInfo.xcprivacy` | Apple te dirá cuál — añádela al manifest |
| `No Accounts` | No has logueado tu Apple ID en Xcode | Xcode → Settings → Accounts → `+` → Apple ID |

### 3.5 Distribute App → TestFlight

Si la validación pasa:

1. **Distribute App** (mismo botón se reusa después de Validate).
2. Mismos toggles que Validate.
3. Click **Upload** → espera 2-10 min → ✅ "App Store Connect upload successful".

### 3.6 En App Store Connect

1. Abre https://appstoreconnect.apple.com → Mis Apps → Personal Finance → **TestFlight**.
2. Tu build aparece en estado **Procesando** (10-30 min).
3. Cuando pase a **Listo para enviar**, Apple te pide:
   - Confirmar **Export Compliance** → tu `ITSAppUsesNonExemptEncryption = false` lo automatiza, pero la primera vez es bueno revisar.
   - **What to Test** (notas para probadores) — 200 caracteres mínimo en cada locale (`en` y `es`).
4. Asigna el build a un **grupo de testers internos** (hasta 100 personas del equipo).
5. Para testers externos (hasta 10.000), pasa por **Beta App Review** (24-48h aprobación).

### 3.7 Promover de TestFlight a App Store

Cuando el build esté estable y probado:

1. App Store Connect → **App Store** → versión `1.1.4` → **+** → seleccionar el build de TestFlight.
2. Completa metadata: screenshots (6.7" y 6.1" requeridos), descripción ES/EN, palabras clave, categoría, soporte URL, privacy policy URL.
3. **Add for Review** → **Submit to Apple Review**.
4. Tiempo de revisión: típicamente 24-72h.

---

## 4. Modo AUTOMÁTICO — Xcode Cloud

Tu repo **ya tiene** `ios/ci_scripts/ci_post_clone.sh` configurado para Flutter. Solo falta crear el workflow en Xcode.

### 4.1 Crear el workflow

En Xcode con el proyecto abierto:

1. Menú **Integrate > Create Workflow…**
2. Selecciona el target **Runner**.
3. Xcode descubre tu repo y se conecta a tu cuenta de Apple Developer (si es primera vez, te pedirá permisos al repositorio GitHub/Bitbucket/GitLab).

### 4.2 Configuración del workflow

**General:**
- **Name:** `Build & Deploy to TestFlight`
- **Description:** `Build automático del branch main para TestFlight`
- **Repository:** tu repo
- **Project/Workspace:** `ios/Runner.xcworkspace` (NO `.xcodeproj`)

**Environment:**
- **Xcode:** `16.x` (la más reciente que soporte tu versión de Flutter)
- **macOS:** Latest Release
- **Clean:** ☐ (sin marcar — más rápido)
- **Environment Variables:**
  - `FLUTTER_VERSION` = tu versión local exacta (corre `flutter --version` en tu terminal y copia el primer número, ej. `3.27.1`)
  - `FLUTTER_CHANNEL` = `stable` (opcional, default ya es stable)

**Start Conditions:**
- **Branch Changes:** `main` (o el branch que uses para releases)
- O **Tag Changes:** patrón `v*` si prefieres releases por tag

**Actions:**
- **Build** (siempre)
- **Test** (opcional — recomendado para PRs)
- **Archive:**
  - Scheme: `Runner`
  - Platform: `iOS`
  - Configuration: `Release`

**Post-Actions:**
- **TestFlight External Testing** (o Internal, según tu setup en App Store Connect)
  - Grupo de testers: el que ya tengas creado

### 4.3 Primera ejecución

1. Click **Start Build** (o haz push al branch configurado).
2. Xcode Cloud:
   - Clona tu repo
   - Ejecuta `ci_post_clone.sh` (instala Flutter + Pods)
   - Compila Archive
   - Firma con cert administrado por Xcode Cloud (es automático, no necesitas exportar nada)
   - Sube a TestFlight
3. Tiempo total: ~20-35 min la primera vez, ~12-18 min las siguientes.

### 4.4 Ver logs

- **Xcode > Report Navigator** (`⌘9`) → pestaña **Cloud** → selecciona tu build → expande cada fase.
- Si falla en `ci_post_clone`: revisa el log de esa fase. El error suele ser `FLUTTER_VERSION` apuntando a un tag que no existe — corre `git ls-remote --tags https://github.com/flutter/flutter.git | grep 3.27` para ver tags válidos.

### 4.5 Costos Xcode Cloud

- **25 horas de compute/mes gratis** con cualquier plan Apple Developer.
- Builds de Flutter consumen ~15 min cada uno → ~100 builds/mes incluidos.
- Si excedes: paquetes desde $49.99/mes por 100h adicionales.

---

## 5. Versionado entre releases

Cada vez que vayas a subir un build nuevo, **debes incrementar el build number** (App Store Connect rechaza duplicados).

Edita solo el número después del `+` en `pubspec.yaml`:

```yaml
version: 1.1.4+5     # build inicial
version: 1.1.4+6     # bugfix subido el mismo día
version: 1.1.5+7     # patch release
version: 1.2.0+8     # nueva feature menor
version: 2.0.0+9     # cambio mayor
```

Reglas:
- **Marketing version** (antes del `+`) sigue [SemVer](https://semver.org). Cambia cuando quieras una nueva versión visible en App Store.
- **Build number** (después del `+`) es un entero monotónicamente creciente. **Nunca lo decrementes ni lo repitas**, aun entre versiones.

Después de editar, corre `flutter pub get` para que Generated.xcconfig se regenere.

---

## 6. Troubleshooting

### "No Account for Team" al hacer Archive
- Xcode → Settings → Accounts → tu Apple ID → Manage Certificates → **+** → Apple Distribution.

### "Provisioning profile doesn't include the X entitlement"
- En Signing & Capabilities, click **Try Again**. Si persiste:
  - Desactiva y reactiva "Automatically manage signing".
  - Borra perfiles en `~/Library/MobileDevice/Provisioning Profiles/`.
  - Reinicia Xcode.

### "Module 'firebase_core' not found" en Archive pero corre en debug
```bash
cd ios && rm -rf Pods Podfile.lock && pod install --repo-update && cd ..
```

### Crashlytics no sube dSYMs
- En Build Phases del target Runner, debe existir un script de Crashlytics. Si no, Firebase ya lo agrega en `pod install`. Verifica que en Validate App marcaste "Upload your app's symbols".

### Build sube pero TestFlight queda en "Procesando" indefinidamente
- Espera 60 min. Si sigue, abre un Caso de Soporte en App Store Connect — generalmente es un fallo intermitente del lado de Apple.

---

## 7. Checklist final pre-submit App Store

| Ítem | Estado |
|---|---|
| `pubspec.yaml` con `version: X.Y.Z+N` (N incrementado) | ☐ |
| `flutter analyze` sin errores | ☐ |
| `flutter test` pasa | ☐ |
| `flutter build ios --release --no-codesign` sin errores | ☐ |
| Bundle ID `com.grullondev.personalFinance` en App Store Connect | ☑️ ya creado |
| Team `7CK75YX2YB` configurado en Xcode con Automatic Signing | ☐ verificar al abrir |
| Capability "Sign in with Apple" activa en developer.apple.com | ☐ verificar (sección 2) |
| `PrivacyInfo.xcprivacy` en `ios/Runner/` y referenciado en pbxproj | ✅ aplicado |
| Privacy strings completos en `Info.plist` (Camera, Photos, FaceID, Mic) | ✅ aplicado |
| `ITSAppUsesNonExemptEncryption = false` | ✅ ya estaba |
| `GoogleService-Info.plist` coincide con el bundle real | ⚠️ ver IOS_MVP_RELEASE_GUIDE.md sección A |
| Ícono 1024×1024 sin canal alpha | ✅ verificado (RGB) |
| Screenshots 6.7" y 6.1" en App Store Connect | ☐ subir antes de Submit Review |
| Privacy Policy URL en App Store Connect | ☐ requerido |
| Support URL en App Store Connect | ☐ requerido |

---

## 8. Referencias

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Xcode Cloud documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios)
- [Required Reason API list](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
