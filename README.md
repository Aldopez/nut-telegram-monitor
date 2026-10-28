# NUT Telegram Monitor

Monitor de UPS basado en [Network UPS Tools (NUT)](https://networkupstools.org/)
que registra el estado eléctrico y envía alertas mediante un bot de Telegram.

## Funciones

- Aviso inmediato cuando la UPS pasa a batería.
- Aviso cuando se restablece la alimentación.
- Alertas de batería baja y pérdida de comunicación.
- Aviso previo al apagado automático.
- Registro periódico en el journal de systemd.
- Informes detallados durante cortes prolongados.
- Notificación después de iniciar el servidor.
- Reintentos de la notificación de arranque hasta recuperar conectividad.

## Requisitos

- Linux con systemd.
- Network UPS Tools instalado y funcionando.
- Una UPS accesible mediante `upsc`.
- `curl`.
- Un bot de Telegram y un chat de destino.

El desarrollo y las pruebas iniciales se realizan sobre Debian. La compatibilidad
con otras distribuciones todavía no ha sido validada.

Antes de instalar el monitor, este comando debe devolver información de la UPS:

```bash
upsc NOMBRE_UPS@HOST
```

## Componentes

| Componente | Función |
|---|---|
| `notificar-ups-telegram` | Convierte eventos de NUT en mensajes de Telegram |
| `registrar-estado-ups` | Consulta métricas, registra el estado y genera informes periódicos |
| `eventos-ups` | Consulta eventos recientes en el journal |
| `ups-startup-notify.service` | Informa el arranque y reintenta si no hay conectividad |
| `ups-status-report.timer` | Ejecuta el registro periódico |
| `upsmon.conf.snippet` | Directivas que deben integrarse manualmente en `upsmon.conf` |
| `install.sh` | Instala los archivos sin habilitar servicios ni reemplazar configuraciones existentes |

## Instalación

Ejecutá el instalador desde la raíz del repositorio:

```bash
sudo ./install.sh
```

El instalador:

- instala los scripts en `/usr/local/bin`;
- instala las unidades en `/etc/systemd/system`;
- crea `/etc/nut/telegram.conf` únicamente si todavía no existe;
- preserva cualquier configuración existente;
- no modifica `upsmon.conf`;
- no habilita ni inicia servicios automáticamente.

## Configuración

Editá:

```bash
sudo nano /etc/nut/telegram.conf
```

Variables disponibles:

| Variable | Descripción |
|---|---|
| `BOT_TOKEN` | Token proporcionado por BotFather |
| `CHAT_ID` | Identificador del usuario, grupo o canal de destino |
| `NOMBRE_EQUIPO` | Etiqueta opcional del servidor; si está vacía se usa el hostname |
| `UPS_TARGET` | Identificador aceptado por `upsc`, por ejemplo `ups@127.0.0.1` |
| `NOMBRE_UPS` | Nombre amigable opcional mostrado en los mensajes |
| `INTERVALO_AVISO` | Segundos entre informes detallados mientras continúa en batería |

La configuración debe permanecer con propietario `root:nut` y modo `0640`.

## Integración con upsmon

Antes de modificar NUT, creá una copia de seguridad:

```bash
sudo cp -a \
    /etc/nut/upsmon.conf \
    "/etc/nut/upsmon.conf.bak-$(date +%Y%m%d%H%M%S)"
```

Integrá manualmente las directivas de:

```text
/usr/local/share/doc/nut-telegram-monitor/upsmon.conf.snippet
```

en:

```text
/etc/nut/upsmon.conf
```

No reemplaces el archivo completo: contiene la definición `MONITOR` y parámetros
propios de cada instalación.

Después de revisar los cambios:

```bash
sudo systemctl restart nut-monitor.service
systemctl status nut-monitor.service --no-pager
```

## Pruebas iniciales

La siguiente prueba envía un mensaje real a Telegram:

```bash
sudo -u nut env \
    NOTIFYTYPE=ONBATT \
    UPSNAME="UPS de prueba" \
    /usr/local/bin/notificar-ups-telegram
```

Para consultar la UPS, registrar su estado y enviar un informe solamente si
corresponde:

```bash
sudo -u nut /usr/local/bin/registrar-estado-ups
```

Consultá el registro:

```bash
journalctl -t ups-history -n 10 --no-pager
```

## Activación

Habilitá el registro periódico:

```bash
sudo systemctl enable --now ups-status-report.timer
```

Prepará la notificación para el próximo arranque:

```bash
sudo systemctl enable ups-startup-notify.service
```

No se utiliza `--now` en la segunda orden para evitar enviar una notificación de
arranque durante la instalación.

Verificá el temporizador:

```bash
systemctl list-timers ups-status-report.timer --no-pager
```

## Consulta de eventos

Por defecto se muestran los últimos 30 días:

```bash
sudo eventos-ups
```

También puede indicarse otra cantidad de días:

```bash
sudo eventos-ups 7
```

## Seguridad

El token del bot y el identificador del chat se guardan en
`/etc/nut/telegram.conf`. Este archivo nunca debe incorporarse a Git ni
compartirse en diagnósticos.

El archivo versionado `config/telegram.conf.example` contiene solamente valores
de ejemplo.

El instalador admite `DESTDIR` para realizar pruebas aisladas sin modificar el
sistema:

```bash
STAGE_DIR=$(mktemp -d)
DESTDIR="$STAGE_DIR" ./install.sh
find "$STAGE_DIR" -type f -print
```

## Desarrollo

Validación sintáctica y estática:

```bash
sh -n install.sh bin/* tests/*
shellcheck install.sh bin/* tests/*
```

Pruebas simuladas, sin UPS ni acceso a Telegram:

```bash
tests/run-tests
tests/test-install
```

GitHub Actions ejecuta estas verificaciones en cada `push` y pull request.

## Licencia

Distribuido bajo la licencia MIT. Consultá [LICENSE](LICENSE).