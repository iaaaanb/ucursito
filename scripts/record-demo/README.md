# record-demo

Regenera `docs/media/demo.gif` a partir de una **corrida real** de ucursito. No
hay que grabar la pantalla a mano ni maquillar la salida: lo que sale en el GIF
es lo que imprimió el comando.

## Uso

```bash
./scripts/record-demo/record.sh terminal ucursito -c
```

La primera corrida instala asciinema y agg en `.herramientas/` (~15 MB).
Requiere `ffmpeg` en el PATH.

Variables: `WIDTH` (ancho del gif, 900), `FPS` (10), `COLS`/`ROWS` (tamaño del
terminal grabado, 100x30), `SPEED` (1.4), `IDLE` (recorte de pausas, 1.5s).

## Los tres modos

**`terminal <comando>`** — el principal. Graba la sesión del terminal con
asciinema y la pasa a GIF con agg. Como captura el tty y no la pantalla, sale
texto nítido, pesa poco (decenas de KB) y funciona igual en Wayland, donde la
captura de pantalla no está disponible desde un script.

**`navegador <comando>`** — levanta un Xvfb y graba ahí el Chromium que maneja
Selenium, para mostrar el scraper navegando U-Cursos. Es la misma idea que el
`recordVideo` de Playwright: se graba una pantalla propia en vez de la del
escritorio, así que el compositor no estorba. Necesita `sudo apt install xvfb`
y correr el scraper con `--no-headless`.

**`gif <video> [inicio] [dur]`** — convierte un video a GIF con paleta acotada.
Para el calendario ya cargado en Thunderbird, que es más fácil grabar con el
capturador de GNOME (Ctrl+Alt+Shift+R, queda en `~/Videos`) y recortar acá.

## Qué grabar

El GIF que mejor resume el proyecto es `ucursito -c`: login, ramos detectados,
controles y plazos extraídos, y el resumen del `.ics` generado. La sincronización
completa dura demasiado para un GIF.

Dos cosas quedan grabadas y conviene decidir antes: el login imprime el nombre
de usuario, y se ven los nombres reales de los ramos.
