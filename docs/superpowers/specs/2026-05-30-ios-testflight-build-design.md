# iOS TestFlight Build — Spec de Diseño

**Fecha:** 2026-05-30
**Objetivo:** Generar un archive firmado de la app iOS y subirlo a TestFlight via Xcode Organizer.

---

## Estado actual del proyecto iOS

| Configuración | Estado |
|---|---|
| Bundle ID | `com.grullondev.personalFinance` ✅ |
| GoogleService-Info.plist | Proyecto `personalfinancedev-e972f`, bundle correcto ✅ |
| Signing | Automático, team `7CK75YX2YB` ✅ |
| Runner.entitlements (Sign in with Apple) | Presente ✅ |
| PrivacyInfo.xcprivacy | Presente en `ios/Runner/` ✅ |
| Info.plist privacy strings | Completos ✅ |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` ✅ |

---

## Fase 1: Pre-build desde terminal

Verificar que el proyecto compila limpio antes de abrir Xcode.

**Comandos en orden:**
```bash
cd /Users/jorgegrullon/Dev/PersonalFinance
fvm flutter clean
fvm flutter pub get
cd ios && pod install --repo-update && cd ..
fvm flutter build ios --release --no-codesign
```

**Criterio de éxito:** `flutter build ios` termina sin errores. Warnings de SPM/Kotlin son no-bloqueantes.

---

## Fase 2: Activar Sign in with Apple en Apple Developer Portal

**Acción requerida (manual, una sola vez):**

1. Ir a [developer.apple.com/account](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles** → **Identifiers**
3. Seleccionar `com.grullondev.personalFinance`
4. Activar el checkbox **Sign in with Apple** → Save
5. Xcode con Automatic signing regenerará el provisioning profile automáticamente

**Por qué es obligatorio:** La app usa el paquete `sign_in_with_apple` y tiene el entitlement `com.apple.developer.applesignin` en `Runner.entitlements`. Apple rechaza builds que declaran este entitlement si el App ID no tiene la capability activada.

---

## Fase 3: Archive y subida desde Xcode

**Pasos:**
1. Abrir `ios/Runner.xcworkspace` (no `.xcodeproj`)
2. En el selector de destino → elegir **Any iOS Device (arm64)** (no un simulador)
3. Menú **Product → Archive**
   - Xcode compilará en modo Release y generará el `.xcarchive` firmado
   - Duración estimada: 5-15 minutos
4. Al terminar, se abre el **Organizer** automáticamente
5. Seleccionar el archive más reciente → clic **Distribute App**
6. Seleccionar **App Store Connect** → **Upload**
7. Mantener las opciones por defecto (bitcode, symbols) → **Next → Upload**
8. Esperar confirmación de subida exitosa

**Post-subida:** El build aparece en App Store Connect → TestFlight en ~15-30 minutos (proceso de validación de Apple).

---

## Criterios de éxito

- [ ] `fvm flutter build ios --release --no-codesign` termina sin errores
- [ ] Archive completa sin errores de codesigning
- [ ] Build visible en App Store Connect → TestFlight
- [ ] Build supera la validación automática de Apple (sin errores de compliance)
