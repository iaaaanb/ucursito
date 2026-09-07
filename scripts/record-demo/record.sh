#!/usr/bin/env bash
# Regenera docs/media/demo.gif a partir de una corrida real de ucursito.
#
#   ./scripts/record-demo/record.sh terminal  ucursito -c
#   ./scripts/record-demo/record.sh navegador ucursito -c --no-headless
#   ./scripts/record-demo/record.sh gif       out/loquesea.webm [inicio] [dur]
#
# Graba salida real: no simula ni maquilla nada. La primera corrida instala
# asciinema y agg en .herramientas/ (~15 MB). Requiere ffmpeg en el PATH; el
# modo navegador ademas necesita Xvfb (sudo apt install xvfb).
#
# Variables: WIDTH (ancho del gif, 900), FPS (10), COLS/ROWS (tamaño del
# terminal grabado, 100x30), SPEED (1.4), IDLE (recorte de pausas, 1.5s).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
HERR="$HERE/.herramientas"
OUT="$HERE/out"
MEDIA="$REPO/docs/media"

WIDTH=${WIDTH:-900}
FPS=${FPS:-10}
COLS=${COLS:-100}
ROWS=${ROWS:-30}
SPEED=${SPEED:-1.4}
IDLE=${IDLE:-1.5}
FONT_SIZE=${FONT_SIZE:-16}
FONT_FAMILY=${FONT_FAMILY:-"JetBrainsMono Nerd Font Mono,DejaVu Sans Mono,Noto Color Emoji"}
THEME=${THEME:-monokai}

AGG_URL="https://github.com/asciinema/agg/releases/latest/download/agg-x86_64-unknown-linux-gnu"

# Misma cadena de filtros que scripts/record-demo de finanzas: una sola pasada,
# paleta acotada y dithering suave. Da GIFs bastante mas livianos que el default.
filtro_gif() { echo "fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=96:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=4"; }

herramientas() {
  mkdir -p "$HERR" "$OUT"
  if [ ! -x "$HERR/venv/bin/asciinema" ]; then
    echo "==> instalando asciinema"
    python3 -m venv "$HERR/venv"
    "$HERR/venv/bin/pip" -q install --upgrade pip
    "$HERR/venv/bin/pip" -q install asciinema
  fi
  if [ ! -x "$HERR/agg" ]; then
    echo "==> descargando agg"
    curl -sSL -o "$HERR/agg" "$AGG_URL"
    chmod +x "$HERR/agg"
  fi
}

publicar() {
  local gif="$1" nombre="${2:-demo.gif}"
  mkdir -p "$MEDIA"
  cp "$gif" "$MEDIA/$nombre"
  echo
  ls -lh "$MEDIA/$nombre"
  local bytes; bytes=$(stat -c%s "$gif")
  if [ "$bytes" -gt 5000000 ]; then
    echo "OJO: pesa mas de 5 MB, GitHub lo va a cargar lento."
    echo "     Reintenta con:  SPEED=2 WIDTH=760 FPS=8 $0 ..."
  fi
  echo
  echo "En el README:  ![demo](docs/media/$nombre)"
}

# Graba la sesion del terminal. No pasa por el compositor, asi que funciona
# igual en Wayland y el texto queda nitido en vez de reescalado.
terminal() {
  herramientas
  [ $# -gt 0 ] || { echo "falta el comando a grabar"; exit 1; }
  echo "==> grabando (${COLS}x${ROWS}): $*"
  "$HERR/venv/bin/asciinema" rec "$OUT/demo.cast" \
    --overwrite --cols "$COLS" --rows "$ROWS" --idle-time-limit "$IDLE" -c "$*"
  echo "==> convirtiendo a gif"
  "$HERR/agg" --font-size "$FONT_SIZE" --font-family "$FONT_FAMILY" \
    --theme "$THEME" --speed "$SPEED" --fps-cap "$FPS" \
    --idle-time-limit "$IDLE" "$OUT/demo.cast" "$OUT/demo.gif"
  publicar "$OUT/demo.gif" demo.gif
}

# Graba el Chromium que maneja Selenium, dentro de un display virtual.
# Es el equivalente al recordVideo de Playwright: se captura una pantalla
# propia en vez de la del escritorio, asi que Wayland no estorba.
navegador() {
  command -v Xvfb >/dev/null || { echo "falta Xvfb: sudo apt install xvfb"; exit 1; }
  [ $# -gt 0 ] || { echo "falta el comando a grabar"; exit 1; }
  mkdir -p "$OUT"
  local disp=:99 geom="1280x800x24"

  echo "==> levantando display virtual $disp ($geom)"
  Xvfb "$disp" -screen 0 "$geom" -nolisten tcp &
  local xvfb_pid=$!
  trap 'kill $xvfb_pid 2>/dev/null || true' EXIT
  sleep 2

  echo "==> grabando pantalla virtual"
  ffmpeg -hide_banner -loglevel error -f x11grab -framerate 25 \
    -video_size "${geom%x*}" -i "$disp" -codec:v libx264 -preset ultrafast \
    -pix_fmt yuv420p -y "$OUT/navegador.mp4" &
  local ff_pid=$!
  sleep 1

  echo "==> corriendo: $*"
  DISPLAY="$disp" "$@" || true

  sleep 1
  kill -INT $ff_pid 2>/dev/null || true
  wait $ff_pid 2>/dev/null || true
  kill $xvfb_pid 2>/dev/null || true
  trap - EXIT

  gif "$OUT/navegador.mp4"
}

# Convierte cualquier video a gif. Sirve para la grabacion de pantalla de
# GNOME (Ctrl+Alt+Shift+R, queda en ~/Videos) cuando quieras mostrar el
# calendario ya cargado en Thunderbird.
gif() {
  local entrada="$1" inicio="${2:-0}" dur="${3:-}"
  [ -f "$entrada" ] || { echo "no existe: $entrada"; exit 1; }
  mkdir -p "$OUT"
  local salida="$OUT/$(basename "${entrada%.*}").gif"
  local recorte=(-ss "$inicio"); [ -n "$dur" ] && recorte+=(-t "$dur")
  echo "==> convirtiendo a gif (${WIDTH}px, ${FPS}fps)"
  ffmpeg -y -loglevel error "${recorte[@]}" -i "$entrada" \
    -vf "$(filtro_gif)" -loop 0 "$salida"
  publicar "$salida" "$(basename "$salida")"
}

case "${1:-}" in
  terminal)  shift; terminal "$@" ;;
  navegador) shift; navegador "$@" ;;
  gif)       shift; gif "$@" ;;
  *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
