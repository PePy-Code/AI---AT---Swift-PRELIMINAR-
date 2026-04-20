#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_ICONSET="${REPO_ROOT}/UIDesignConcept/AppIcon.appiconset"

if [[ ! -d "${SOURCE_ICONSET}" ]]; then
  echo "❌ No se encontró el icon set en: ${SOURCE_ICONSET}" >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 /ruta/a/TuApp/Assets.xcassets"
  exit 1
fi

TARGET_ASSETS="$1"
if [[ "${TARGET_ASSETS}" != *.xcassets ]]; then
  echo "❌ Debes pasar la ruta de Assets.xcassets" >&2
  exit 1
fi

if [[ ! -d "${TARGET_ASSETS}" ]]; then
  echo "❌ No existe la carpeta destino: ${TARGET_ASSETS}" >&2
  exit 1
fi

TARGET_ICONSET="${TARGET_ASSETS}/AppIcon.appiconset"
rm -rf "${TARGET_ICONSET}"
cp -R "${SOURCE_ICONSET}" "${TARGET_ICONSET}"

echo "✅ App icon instalado en: ${TARGET_ICONSET}"
echo "ℹ️  En Xcode, verifica que el target use ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon."
echo "ℹ️  Si el simulador mantiene el icono anterior, elimina la app del simulador y vuelve a correr."
