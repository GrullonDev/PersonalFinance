#!/usr/bin/env bash
# Publica en Firebase Remote Config la versión de pubspec.yaml como la más
# nueva, para que las instalaciones anteriores muestren "Nueva versión
# disponible". Ejecútalo cuando el build ya esté disponible en TestFlight /
# Google Play (no antes: el usuario no tendría qué instalar).
#
# Requiere Firebase CLI con sesión iniciada (`firebase login`).
#
# Uso (desde la raíz del proyecto):
#   ./scripts/publish_version.sh ios
#   ./scripts/publish_version.sh android
#   ./scripts/publish_version.sh all
set -euo pipefail

cd "$(dirname "$0")/.."
TARGET="${1:-}"
case "$TARGET" in
  ios) KEYS="update_latest_ios" ;;
  android) KEYS="update_latest_android" ;;
  all) KEYS="update_latest_ios update_latest_android" ;;
  *) echo "Uso: $0 ios|android|all" >&2; exit 1 ;;
esac

VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/version:[[:space:]]*//')"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "La versión de pubspec.yaml debe tener el formato X.Y.Z+N (actual: $VERSION)" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

firebase remoteconfig:get -o "$TMP/template.json" >/dev/null

python3 - "$TMP/template.json" "$VERSION" $KEYS <<'PY'
import json, sys
path, version, keys = sys.argv[1], sys.argv[2], sys.argv[3:]
with open(path) as f:
    template = json.load(f)
template.pop("version", None)
params = template.setdefault("parameters", {})
for key in keys:
    param = params.setdefault(key, {})
    param["defaultValue"] = {"value": version}
    param.setdefault("valueType", "STRING")
with open(path, "w") as f:
    json.dump(template, f, indent=2)
PY

cat > "$TMP/firebase.json" <<JSON
{ "remoteconfig": { "template": "template.json" } }
JSON
cp .firebaserc "$TMP/"

(cd "$TMP" && firebase deploy --only remoteconfig --non-interactive)
echo "Publicado $VERSION en: $KEYS"
