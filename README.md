<div align="center">

# 🎵 MelodyFlow Studio

**Genera música con IA en tu propio equipo: local, gratuita e ilimitada.**

Interfaz web moderna y visual conectada a [ACE-Step](https://github.com/ace-step), el modelo de generación musical de código abierto. Sin límites, sin nubes, sin suscripciones: todo corre en tu máquina.

![Estado](https://img.shields.io/badge/estado-activo-brightgreen)

</div>

---

## ✨ Características

- 🎵 **Generación desde texto** — describe tu canción (o pega una letra) y MelodyFlow la crea.
- 🎧 **Remix / Cover** — sube un audio de referencia y transformalo a un nuevo estilo con intensidad ajustable.
- 🎨 **Herramientas de estilo** — elige género (13), mood (10), instrumentos (12) y voces (6) con selectores de chips; se inyectan en el prompt automáticamente.
- ✨ **Efectos visuales en tiempo real** — barras 3D, waveform, pulsos, aurora y vinilo que reaccionan al audio mientras suena.
- 📊 **Visualizador de espectro + "Melody Player"** — análisis de frecuencia en vivo y frase motivacional aleatoria al escuchar.
- 🔊 **Notificación de sonido** — un chime te avisa cuando la generación termina.
- 📂 **Historial persistente** — las canciones se guardan en el servidor y reaparecen aunque cierres o recargues la pestaña (resiliente a interrupciones).
- 🗑 **Eliminar canciones** — si una no te gusta, bórrala de la lista (archivo y registro).
- 🏷 **Logo de marca** — coloca `logo.png` junto a `index.html` y aparecerá en la esquina.

## 🖼 Vista previa

```
┌──────────────────────────────────────────────┐
│ (JMB)  MelodyFlow Studio            ● servidor│
│         Generación de música con IA local     │
│                                              │
│  [modo: crear desde cero | remix]            │
│  Prompt: ________________________________    │
│  Letra (opcional): ______________________    │
│  Duración [30s]  Pasos [16 · rápido ▼]  ...  │
│                                              │
│  [🎵 Generar música]   ▓▓▓▓▓▓░░░░ 45%        │
│                                              │
│  Estilo: [Rock][Balada][Alegre][Épico]...    │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │ 🎵 Canción 1              [🗑 Eliminar] │  │
│  │ ▶ ────────────────────────────        │  │
│  │ ✨ Visualizador   🎧 Melody Player      │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

---

## 🚀 Instalación

### Requisitos

- **ACE-Step** instalado y funcional (CPU o GPU, NVIDIA recomendada para velocidad).
- Python 3.11+ y `uv` (el gestor de entornos que usa ACE-Step).
- Git (para clonar).

### 1. Clona la interfaz

```bash
git clone https://github.com/josemanueb/melodyflow-studio.git ~/Desktop/MelodyFlow-Studio
```

### 2. Arranca el backend de ACE-Step (API en el puerto 7861)

```bash
cd ~/Downloads/ACE-Step
uv run --no-sync acestep \
  --enable-api \
  --config_path acestep-v15-base \
  --device cpu \
  --quantization none \
  --init_llm false \
  --port 7861 \
  --server-name 127.0.0.1
```

> **Nota para CPU sin AVX2** (p. ej. AMD FX): usa siempre `--no-sync` con `uv run`, o `uv` intentará descargar un wheel de Windows de `flash-attn` y fallará.

### 3. Sirve la web (puerto 7862)

```bash
cd ~/Desktop/MelodyFlow-Studio
python3 -m http.server 7862 --bind 127.0.0.1 --directory .
```

> La web debe servirse por HTTP: abrir el `.html` directamente (`file://`) desde algunos editores puede mostrar el código en lugar de la interfaz.

### 4. Abre el navegador

**http://127.0.0.1:7862/index.html**

---

## 🚀 Lanzador automático (`start_melodyflow.sh`)

En lugar de arrancar todo a mano, usa el script:

```bash
bash ~/Desktop/MelodyFlow-Studio/start_melodyflow.sh
```

Hace todo por ti:

1. Activa la swap si es necesario.
2. Arranca la API de ACE-Step en el puerto **7861** (si no está ya en marcha) con timeout de generación de **10 horas**.
3. Espera hasta 5 minutos a que el servidor responda en `/health`.
4. Sirve la web en el puerto **7862**.
5. Abre la interfaz en tu navegador predeterminado.

También puedes añadir un acceso directo en el escritorio apuntando al script.

## 🪟 Windows (`.bat`)

Para usar MelodyFlow Studio en Windows:

1. Clona el repo (o descarga `index.html`, `start_melodyflow.bat` y `logo.png` si lo tienes) en una carpeta.
2. Asegúrate de tener **Python** (marca "Add to PATH" al instalarlo) y **`uv`** (`pip install uv`).
3. Ten ACE-Step descargado en una carpeta (p. ej. `C:\ACE-Step`) y edita la línea `set "ACESTEP_DIR=C:\ACE-Step"` del `.bat` si tu carpeta es otra.
4. Haz doble clic en **`start_melodyflow.bat`**:

   - Verifica Python y `uv`.
   - Arranca la API de ACE-Step en el puerto **7861** (ventana "ACE-Step API").
   - Espera a que responda (hasta 5 min).
   - Sirve la web en el puerto **7862** (ventana "MelodyFlow Web").
   - Abre la interfaz en el navegador.

Para detener todo, cierra las ventanas **"ACE-Step API"** y **"MelodyFlow Web"**.

---

## 🔌 API del backend

La web usa los siguientes endpoints del API de ACE-Step:

| Endpoint | Método | Uso |
|---|---|---|
| `/health` | GET | Estado del servidor |
| `/upload_reference` | POST | Sube el audio de referencia para remix |
| `/release_task` | POST | Lanza la generación (devuelve `task_id` al instante) |
| `/query_result` | POST | Consulta el estado/resultado de una tarea |
| `/get_history` | GET | Lista todos los resultados guardados |
| `/delete_result` | POST | Elimina una canción (archivo + registro) |
| `/v1/audio?path=…` | GET | Descarga el audio generado |

La generación es **asíncrona**: la web hace polling a `/query_result` cada 20 s hasta que la canción está lista, y persiste el `task_id` en `localStorage` para recuperarla aunque recargues la página.

---

## ⚙️ Consejos de rendimiento

| Hardware | Recomendado |
|---|---|
| GPU NVIDIA (6+ GB VRAM) | 32 pasos, 30 s, ~1-3 min por canción |
| CPU moderno (AVX2) | 16 pasos, 20-30 s, ~15-45 min por canción |
| CPU sin AVX2 | 16 pasos, 20 s (30 s puede tardar horas) |

- **Pasos**: `16` es rápido y suena bien; `32` da más detalle pero dobla el tiempo.
- **Duración**: a partir de 30 s los tiempos de CPU crecen mucho.
- Ajusta `ACESTEP_GENERATION_TIMEOUT` en `start_melodyflow.sh` (por defecto `36000` s = 10 h) si generas en CPU con muchos pasos.

---

## 🔒 Privacidad

- ✅ Todo se procesa **en local** — ninguna pista sube a la nube.
- ✅ **Ilimitado** — genera tantas canciones como quieras.
- ✅ Sin cuentas, sin anuncios, sin planes.

---

## 📁 Estructura

```
melodyflow-studio/
├── index.html              # La aplicación web completa (CSS + JS + HTML)
├── start_melodyflow.sh     # Lanzador automático para Linux (API + web + navegador)
├── start_melodyflow.bat    # Lanzador automático para Windows
└── README.md
```

> ⚠️ Este repositorio contiene **solo la interfaz**. El modelo de IA y el backend pertenecen a [ACE-Step](https://github.com/ace-step), que debe instalarse por separado.

---

## 🤝 Contribuir

¿Ideas, bugs o mejoras? Abre un [issue](https://github.com/josemanueb/melodyflow-studio/issues) o propón un *pull request*.

## 📜 Licencia

Uso personal y educativo. El backend (modelo) sigue la licencia de [ACE-Step](https://github.com/ace-step).