#!/usr/bin/env bash
# Sube la versión (patch +1 y build +1) y genera el build de tienda.
#
# El MAJOR.MINOR se cambia a mano en pubspec.yaml (ej. 1.2.x → 1.3.0);
# este script sólo incrementa el PATCH y el número de build de uno en uno:
#   1.2.2+1  →  1.2.3+2  →  1.2.4+3 ...
#
# Uso (desde la raíz del proyecto):
#   ./scripts/release.sh ios        # sube versión y genera el .ipa
#   ./scripts/release.sh android    # sube versión y genera el .aab (usa .env)
#   ./scripts/release.sh all        # una sola versión para ambas plataformas
#   ./scripts/release.sh bump       # sólo sube la versión, sin compilar
set -euo pipefail

cd "$(dirname "$0")/.."
TARGET="${1:-}"
case "$TARGET" in
  ios|android|all|bump) ;;
  *) echo "Uso: $0 ios|android|all|bump" >&2; exit 1 ;;
esac

FLUTTER="flutter"
command -v fvm >/dev/null 2>&1 && FLUTTER="fvm flutter"

CURRENT="$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/version:[[:space:]]*//')"
if [[ ! "$CURRENT" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)$ ]]; then
  echo "La versión de pubspec.yaml debe tener el formato X.Y.Z+N (actual: $CURRENT)" >&2
  exit 1
fi
MAJOR="${BASH_REMATCH[1]}"; MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"; BUILD="${BASH_REMATCH[4]}"
NEW="$MAJOR.$MINOR.$((PATCH + 1))+$((BUILD + 1))"

# sed compatible con macOS y Linux.
sed -i.bak -E "s/^version:.*/version: $NEW/" pubspec.yaml && rm -f pubspec.yaml.bak
echo "Versión: $CURRENT → $NEW"

if [[ "$TARGET" == "bump" ]]; then exit 0; fi

# Limpia archivos ._* que macOS crea en discos externos y rompen la firma.
find . -name '._*' -type f -delete 2>/dev/null || true
$FLUTTER pub get

if [[ "$TARGET" == "ios" || "$TARGET" == "all" ]]; then
  $FLUTTER build ipa --release
  echo "IPA listo. Abre el archive para subirlo:"
  echo "  open build/ios/archive/Runner.xcarchive"
fi

if [[ "$TARGET" == "android" || "$TARGET" == "all" ]]; then
  if [[ ! -f .env && ! -f android/key.properties ]]; then
    echo "Falta .env con los datos de firma (ver .env.example)." >&2
    exit 1
  fi
  $FLUTTER build appbundle --release
  echo "AAB listo: build/app/outputs/bundle/release/app-release.aab"
fi

echo
echo "Recuerda guardar la versión en git:"
echo "  git add pubspec.yaml && git commit -m \"chore: versión $NEW\" && git push"
