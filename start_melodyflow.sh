#!/bin/bash
# MelodyFlow Studio - lanza el servidor ACE-Step (puerto 7861) y la interfaz web (puerto 7862)
export PATH="$HOME/.local/bin:$PATH"
export ACESTEP_GENERATION_TIMEOUT=36000
export ACESTEP_CONFIG_PATH="${ACESTEP_CONFIG_PATH:-acestep-v15-turbo}"
# Anti-OOM en GPU de 5.6GB (tier2): INT8 + offload del DiT a CPU
export ACESTEP_QUANTIZATION="${ACESTEP_QUANTIZATION:-int8_weight_only}"
export ACESTEP_OFFLOAD_DIT_TO_CPU="${ACESTEP_OFFLOAD_DIT_TO_CPU:-true}"
export ACESTEP_OFFLOAD_TO_CPU="${ACESTEP_OFFLOAD_TO_CPU:-true}"
ACESTEP_DIR="$HOME/Downloads/ACE-Step"
WEB_DIR="$HOME/Desktop/melodyflow-studio-main"
cd "$ACESTEP_DIR"

# Crea el acceso directo del escritorio si no existe (icono incluido)
if [ -f "$WEB_DIR/icon.jpeg" ] && [ ! -f "$HOME/Desktop/MelodyFlow.desktop" ]; then
  cat > "$HOME/Desktop/MelodyFlow.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=MelodyFlow Studio
Comment=Generación de música con IA (ACE-Step)
Exec=$WEB_DIR/start_melodyflow.sh
Icon=$WEB_DIR/icon.jpeg
Terminal=false
Categories=AudioVideo;Audio;Music;
StartupNotify=true
EOF
  chmod +x "$HOME/Desktop/MelodyFlow.desktop"
  gio set "$HOME/Desktop/MelodyFlow.desktop" metadata::trusted true 2>/dev/null || true
  echo "Acceso directo creado: $HOME/Desktop/MelodyFlow.desktop"
fi

# Auto-activate swap if not active
if ! swapon --show | grep -q swapfile; then
  sudo swapon /home/swapfile_framepack 2>/dev/null
fi

# Start ACE-Step API server (port 7861) if not already running
if ! curl -sf http://127.0.0.1:7861/health >/dev/null 2>&1; then
  setsid nohup uv run --no-sync acestep-api \
    --host 127.0.0.1 \
    --port 7861 > /tmp/melodyflow.log 2>&1 < /dev/null &
  disown

  # Wait for server to become ready (max 5 minutes)
  ok=0
  for i in $(seq 1 60); do
    if curl -sf http://127.0.0.1:7861/health >/dev/null 2>&1; then
      ok=1
      break
    fi
    sleep 5
  done
  if [ "$ok" -ne 1 ]; then
    echo "AVISO: el servidor ACE-Step no respondió en 5 minutos. Revisa /tmp/melodyflow.log" >&2
  fi
fi

# Serve the web interface over HTTP so the browser (not the text editor) opens it
if ! curl -sf http://127.0.0.1:7862/index.html >/dev/null 2>&1; then
  setsid nohup python3 -m http.server 7862 --bind 127.0.0.1 \
    --directory "$WEB_DIR" > /tmp/melodyflow_web.log 2>&1 < /dev/null &
  disown
  sleep 1
fi

# Open the interface in the default web browser
xdg-open http://127.0.0.1:7862/index.html 2>/dev/null || true
exit 0