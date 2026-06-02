# iOS TestFlight Build — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Compilar la app iOS en modo Release, verificar que todo pasa, y subirla a TestFlight via Xcode Organizer.

**Architecture:** Pre-build desde terminal con `fvm flutter` + `pod install`, luego Archive manual desde Xcode apuntando a `Any iOS Device (arm64)`, upload via Xcode Organizer a App Store Connect. Signing automático con team `7CK75YX2YB`.

**Tech Stack:** Flutter 3.44.0 (via fvm), Xcode 26.5, CocoaPods 1.16.2, Apple Developer team `7CK75YX2YB`, App Store Connect.

---

## Archivos involucrados

| Archivo | Acción |
|---|---|
| `ios/Runner.xcworkspace` | Abrir en Xcode para Archive |
| `ios/Podfile.lock` | Puede actualizarse con `pod install --repo-update` |
| `pubspec.yaml` | Verificar versión antes del build |

Sin cambios de código — este plan es 100% build/deploy.

---

## Task 1: Pre-build desde terminal

**Files:**
- No se modifican archivos de código

- [ ] **Step 1: Verificar la versión en pubspec.yaml**

```bash
grep "^version:" /Users/jorgegrullon/Dev/PersonalFinance/pubspec.yaml
```

Esperado: `version: 1.1.4+5` (o la versión actual). El número después de `+` es el build number — debe ser mayor que el último subido a TestFlight. Si necesitas incrementarlo, edita `pubspec.yaml` cambiando `+5` por `+6` (o el siguiente número disponible).

- [ ] **Step 2: Limpiar artefactos anteriores**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && fvm flutter clean
```

Esperado: `Deleting build...` sin errores.

- [ ] **Step 3: Obtener dependencias Dart**

```bash
fvm flutter pub get
```

Esperado: `Got dependencies!` o `Resolving dependencies... (X packages)`.

- [ ] **Step 4: Instalar/actualizar pods de iOS**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance/ios && pod install --repo-update && cd ..
```

Esperado: `Pod installation complete! There are X dependencies from the Podfile and X total pods installed.`
Si hay warnings de deprecación de CocoaPods, son no-bloqueantes.

- [ ] **Step 5: Smoke test — compilar sin firmar**

```bash
cd /Users/jorgegrullon/Dev/PersonalFinance && fvm flutter build ios --release --no-codesign
```

Esperado: termina con `✓ Built build/ios/iphoneos/Runner.app`
- Warnings de SPM (`SwiftPackageManager`): no-bloqueantes
- Warnings de Kotlin Gradle Plugin: no aplican a iOS, ignorar
- **Si hay ERRORES**: stop — reportar el error antes de continuar

- [ ] **Step 6: Confirmar que el smoke test pasó**

```bash
ls -lh /Users/jorgegrullon/Dev/PersonalFinance/build/ios/iphoneos/Runner.app
```

Esperado: el directorio `Runner.app` existe con tamaño > 0.

---

## Task 2: Activar Sign in with Apple en Apple Developer Portal

**Files:**
- No se modifican archivos — acción en navegador web

> Esta acción es **obligatoria**. La app tiene `com.apple.developer.applesignin` en `Runner.entitlements`. Si el App ID no tiene la capability activada, el Archive fallará con error de codesigning o App Store Connect rechazará el build.

- [ ] **Step 1: Ir al Apple Developer Portal**

Abrir en el navegador: `https://developer.apple.com/account/resources/identifiers/list`

Iniciar sesión con el Apple ID del team `7CK75YX2YB`.

- [ ] **Step 2: Localizar el App ID**

En la lista de Identifiers, buscar y seleccionar:
- **Name:** personal_finance (o similar)
- **Identifier:** `com.grullondev.personalFinance`

- [ ] **Step 3: Activar Sign in with Apple**

En la página del App ID:
1. Scroll hasta la sección **Capabilities**
2. Buscar **Sign in with Apple**
3. Activar el checkbox
4. En el dropdown que aparece, seleccionar **Enable as a primary App ID**
5. Clic **Save** (arriba a la derecha)
6. Confirmar el diálogo que aparece

- [ ] **Step 4: Verificar que se guardó**

La página debe mostrar **Sign in with Apple** con checkbox marcado sin errores. Xcode con Automatic signing descargará el provisioning profile actualizado automáticamente al abrir el proyecto.

---

## Task 3: Archive y subida a TestFlight desde Xcode

**Files:**
- `ios/Runner.xcworkspace` — abrir este archivo (NO `Runner.xcodeproj`)

- [ ] **Step 1: Abrir el workspace en Xcode**

```bash
open /Users/jorgegrullon/Dev/PersonalFinance/ios/Runner.xcworkspace
```

Esperar a que Xcode indexe el proyecto (~30-60 segundos).

- [ ] **Step 2: Seleccionar destino correcto**

En la barra de herramientas de Xcode (arriba al centro):
- Clic en el selector de destino
- Elegir **Any iOS Device (arm64)**

> **IMPORTANTE:** No seleccionar un simulador. Archive solo funciona con un dispositivo real o "Any iOS Device".

- [ ] **Step 3: Verificar signing en Xcode**

En el Project Navigator → clic en **Runner** (azul) → pestaña **Signing & Capabilities** → target **Runner**:
- **Automatically manage signing:** ✅ activado
- **Team:** GrullonDev (7CK75YX2YB)
- **Bundle Identifier:** `com.grullondev.personalFinance`
- **Provisioning Profile:** debe decir "Xcode Managed Profile" (sin errores en rojo)

Si hay un error rojo de signing, clic en **Try Again** o en **Download Manual Profile**. Xcode lo resolverá automáticamente ahora que Sign in with Apple está activado en el portal.

- [ ] **Step 4: Ejecutar Archive**

Menú **Product → Archive**

- Duración estimada: 5-15 minutos (primera vez puede tardar más)
- Durante el Archive, Xcode muestra una barra de progreso en el Activity Viewer (arriba al centro)
- Al terminar, se abre automáticamente el **Organizer** con el archive listo

- [ ] **Step 5: Verificar el archive en Organizer**

En el Organizer:
- El archive debe aparecer en la lista con la versión `1.1.4 (5)` (o la versión de pubspec)
- El estado debe ser **Ready to Distribute** (sin warnings críticos)
- Clic **Distribute App**

- [ ] **Step 6: Configurar la distribución**

En el wizard de distribución:
1. Seleccionar **App Store Connect** → **Next**
2. Seleccionar **Upload** (no Export) → **Next**
3. Mantener todas las opciones por defecto:
   - ✅ Include bitcode for iOS content
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number (opcional — deja que Xcode maneje)
4. Clic **Next**

- [ ] **Step 7: Firmar y subir**

1. En la pantalla de signing, seleccionar **Automatically manage signing**
2. Clic **Next** → aparecerá un resumen del contenido
3. Verificar que muestra:
   - App: `personal_finance`
   - Bundle ID: `com.grullondev.personalFinance`
   - Version: `1.1.4`, Build: `5` (o los valores de pubspec)
4. Clic **Upload**
5. Esperar la confirmación: `Upload Successful — Your app has been uploaded to App Store Connect.`

- [ ] **Step 8: Verificar en App Store Connect**

Abrir `https://appstoreconnect.apple.com` → tu app → **TestFlight** → **iOS Builds**

El build aparecerá primero como **Processing** (~10-30 minutos) y luego como **Ready to Test**.

---

## Checklist final

- [ ] `fvm flutter build ios --release --no-codesign` sin errores
- [ ] Sign in with Apple activado en Apple Developer Portal
- [ ] Archive completado en Xcode sin errores de codesigning
- [ ] Build subido exitosamente a App Store Connect
- [ ] Build visible en TestFlight como "Ready to Test"
