#!/bin/bash
# MelodyFlow Studio - desinstalador (Linux)
# Detiene servidores, borra backend ACE-Step, uv, caches de modelos, logs
# y la propia carpeta de la app. No toca el swapfile.
set -u

APP_DIR="$HOME/Desktop/melodyflow-studio-main"
ACESTEP_DIR="$HOME/Downloads/ACE-Step"

echo "=== Deteniendo servidores (puertos 7861/7862) ==="
for pat in "acestep-api" "http.server 7862"; do
  for pid in $(pgrep -f "$pat" 2>/dev/null); do
    kill "$pid" 2>/dev/null && echo "  detenido PID $pid ($pat)"
  done
done
sleep 1

echo "=== Borrando backend ACE-Step (~18 GB) ==="
rm -rf "$ACESTEP_DIR"

echo "=== Borrando uv y sus caches ==="
rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
rm -rf "$HOME/.cache/uv" "$HOME/.local/share/uv"

echo "=== Borrando caches de modelos (HuggingFace/Torch) ==="
rm -rf "$HOME/.cache/huggingface" "$HOME/.cache/torch"

echo "=== Borrando logs y temporales ==="
rm -f /tmp/melodyflow.log /tmp/melodyflow_web.log /tmp/test.mp3
rm -rf /tmp/melodyflow_references

echo "=== Borrando acceso directo del escritorio ==="
rm -f "$HOME/Desktop/MelodyFlow.desktop"

echo "=== Borrando la carpeta de la app (incluye este script) ==="
cd /tmp 2>/dev/null || exit 1
rm -rf "$APP_DIR"

echo "Desinstalación completada. Todo limpio."