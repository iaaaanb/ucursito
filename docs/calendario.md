# Calendario

`python src/main.py -c` recorre las secciones Calendario y Tareas de cada ramo y
escribe un archivo `.ics` en `downloads/calendar.ics`.

## Qué eventos se generan

**Controles**, tomados de las filas bajo el separador "Control" de la sección
Calendario:

- Título `[Abreviación] Nombre del control`
- Hora de inicio y término parseadas del rango `(13:00 - 16:00)`
- Recordatorios un día antes y una hora antes

**Tareas**, tomadas de la sección Tareas:

- Título `[Abreviación] Nombre de la tarea [✓/✗]`, donde ✓ es entregada, ✗ sin
  entrega, y sin símbolo significa pendiente
- El plazo principal como evento
- Si la tarea acepta atrasos, un **segundo evento** con el sufijo `- Atraso` en
  la fecha del plazo extendido
- El estado (Finalizada / En Plazo) en la descripción
- Recordatorio un día antes

Las abreviaciones de ramo salen de `COURSE_ABBREVIATIONS` en `config.py` y solo
se usan en los títulos de los eventos, no en los nombres de carpeta.

## Importar el archivo

- **Google Calendar:** Configuración → Importar y exportar → Importar
- **Apple Calendar:** Archivo → Importar
- **Outlook:** Archivo → Abrir y exportar → Importar o exportar
- **Thunderbird:** Eventos → Importar

## Suscribirse en vez de importar

Importar a mano obliga a repetir el proceso en cada sincronización. La
alternativa es levantar un servidor local que sirva el `.ics`, y suscribir el
calendario a esa URL:

```bash
python src/main.py --serve-calendar              # localhost:8000
python src/main.py --serve-calendar --port 9000
```

El servidor entrega el archivo como `text/calendar` y con cabeceras `no-cache`,
para que la app de calendario vea siempre la última versión en vez de una
cacheada.

Luego, en tu cliente:

- **Thunderbird:** clic derecho en la lista de calendarios → Nuevo calendario →
  En la red → `http://localhost:8000/calendar.ics`
- **Google Calendar:** Configuración → Añadir calendario → Desde URL
- **Apple Calendar:** Archivo → Nueva suscripción a calendario

Cada vez que vuelvas a correr el scraper, el archivo se regenera y los clientes
lo recogen en su próximo refresco. El servidor tiene que quedar corriendo
mientras quieras que la suscripción funcione; se detiene con `Ctrl+C`.

Con `--host 0.0.0.0` el calendario queda accesible desde otras máquinas de la
red. No hay ninguna autenticación delante, así que cualquiera en esa red puede
leer tus fechas de entrega.
