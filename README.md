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

## Componentes

| Componente | Función |
|---|---|
| `notificar-ups-telegram` | Convierte eventos de NUT en mensajes de Telegram |
| `registrar-estado-ups` | Consulta métricas, registra el estado y genera informes periódicos |
| `eventos-ups` | Consulta eventos recientes en el journal |
| `ups-startup-notify.service` | Informa el arranque y reintenta si no hay conectividad |
| `ups-status-report.timer` | Ejecuta el registro periódico |
| `upsmon.conf.snippet` | Directivas que deben integrarse en `upsmon.conf` |

## Requisitos

- Linux con systemd.
- Network UPS Tools.
- `curl`.
- Una UPS configurada y accesible mediante `upsc`.
- Un bot de Telegram y un chat de destino.

El desarrollo y las pruebas iniciales se realizan sobre Debian. La compatibilidad
con otras distribuciones todavía no ha sido validada.

## Seguridad

El token del bot y el identificador del chat se guardan en
`/etc/nut/telegram.conf`. Ese archivo debe pertenecer a `root:nut`, tener permisos
restrictivos y nunca incorporarse al repositorio.

El archivo `config/telegram.conf.example` contiene solamente valores de ejemplo.

## Estado del proyecto

El proyecto está en preparación. El procedimiento de instalación, las pruebas
automatizadas y el instalador todavía se están desarrollando.

## Licencia

Distribuido bajo la licencia MIT. Consultá [LICENSE](LICENSE).