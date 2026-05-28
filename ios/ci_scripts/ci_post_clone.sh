#!/bin/sh

# ci_post_clone.sh — Xcode Cloud post-clone hook
#
# Xcode Cloud clona el repo y ejecuta este script ANTES de cualquier fase de
# build (Archive, Test, etc.). Lo usamos para:
#   1. Instalar Flutter desde el canal stable (o versión fijada)
#   2. Ejecutar `flutter pub get` para resolver paquetes Dart y generar
#      Generated.xcconfig / .symlinks
#   3. Ejecutar `pod install` para integrar plugins de Flutter
#      (firebase_messaging, local_auth_darwin, etc.) en el proyecto Xcode
#
# Variables de entorno en el workflow de Xcode Cloud (opcionales):
#   FLUTTER_VERSION  — tag/rama exacta (ej. "3.27.1"). Si no se define, usa stable.
#   FLUTTER_CHANNEL  — canal por defecto cuando no hay versión fija (default: stable)
#
# IMPORTANTE: Antes del primer Archive en Xcode Cloud, asegúrate de configurar
# FLUTTER_VERSION en el workflow con la MISMA versión que tu máquina local
# (corre `flutter --version` para verla). De lo contrario el build puede
# regresar con incompatibilidades de Dart SDK o de plugins.
#
# Referencia: https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

set -e          # exit on error
set -u          # error on unset variable
# `pipefail` no es POSIX puro pero bash/dash lo soportan
set -o pipefail 2>/dev/null || true

# ── 0. Helpers ────────────────────────────────────────────────────────────────
log() { echo "[ci_post_clone] $*"; }
fail() { echo "[ci_post_clone] ERROR: $*" >&2; exit 1; }

# ── 1. Resolver versión de Flutter ────────────────────────────────────────────
# - Si FLUTTER_VERSION está definido en el workflow → clonar ese tag exacto
# - Si no → usar el canal stable (siempre disponible)
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_HOME="$HOME/flutter"
FLUTTER="$FLUTTER_HOME/bin/flutter"

if [ -n "${FLUTTER_VERSION:-}" ]; then
  FLUTTER_BRANCH="$FLUTTER_VERSION"
  log "Flutter solicitado: tag $FLUTTER_VERSION"
else
  FLUTTER_BRANCH="$FLUTTER_CHANNEL"
  log "Flutter solicitado: canal $FLUTTER_CHANNEL (no se definió FLUTTER_VERSION)"
fi

# ── 2. Instalar Flutter SDK ───────────────────────────────────────────────────
# Xcode Cloud NO cachea $HOME entre runs por defecto, así que descargamos
# siempre. El `if` evita una clonación redundante si se habilita caché.
if [ ! -x "$FLUTTER" ]; then
  log "Clonando Flutter ($FLUTTER_BRANCH)…"
  git clone \
    --depth 1 \
    --branch "$FLUTTER_BRANCH" \
    https://github.com/flutter/flutter.git \
    "$FLUTTER_HOME" || fail "No se pudo clonar Flutter en la rama/tag '$FLUTTER_BRANCH'. Verifica el valor."
else
  log "Flutter SDK ya presente en $FLUTTER_HOME — saltando clonación."
fi

# Añadir Flutter y Dart al PATH para los siguientes comandos del script.
export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

log "Versión instalada:"
flutter --version || fail "El binario flutter no funciona."

# Pre-descargar artefactos del engine (necesario para pub y pod).
log "flutter precache --ios…"
flutter precache --ios

# ── 3. Resolver dependencias Dart / pub ───────────────────────────────────────
# REPO_ROOT está dos niveles arriba de ios/ci_scripts/.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
log "Project root: $REPO_ROOT"

log "flutter pub get…"
flutter pub get --directory="$REPO_ROOT"

# ── 4. Instalar dependencias CocoaPods ────────────────────────────────────────
# Los agentes de Xcode Cloud traen Ruby + CocoaPods, pero la versión puede
# diferir de la local. Instalamos/actualizamos a nivel usuario por seguridad.
log "Asegurando CocoaPods…"
gem install cocoapods --user-install --no-document >/dev/null 2>&1 || true
GEM_USER_DIR="$(ruby -e 'puts Gem.user_dir' 2>/dev/null || echo "$HOME/.gem")"
export GEM_HOME="$GEM_USER_DIR"
export PATH="$GEM_USER_DIR/bin:$PATH"

cd "$REPO_ROOT/ios"
log "pod install --repo-update…"
pod install --repo-update

log "✅ Setup completo: Flutter + Pods listos para Archive."
