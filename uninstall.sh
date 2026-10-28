#!/bin/sh

set -eu

DESTDIR="${DESTDIR:-}"
PREFIX="${PREFIX:-/usr/local}"
SYSCONFDIR="${SYSCONFDIR:-/etc/nut}"
SYSTEMD_UNIT_DIR="${SYSTEMD_UNIT_DIR:-/etc/systemd/system}"
REMOVE_CONFIG="${REMOVE_CONFIG:-0}"

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

target_path() {
    printf '%s%s\n' "$DESTDIR" "$1"
}

case "$DESTDIR" in
    ''|/*) ;;
    *) fail "DESTDIR debe ser una ruta absoluta" ;;
esac

case "$PREFIX:$SYSCONFDIR:$SYSTEMD_UNIT_DIR" in
    /*:/*:/*) ;;
    *) fail "PREFIX, SYSCONFDIR y SYSTEMD_UNIT_DIR deben ser rutas absolutas" ;;
esac

case "$REMOVE_CONFIG" in
    0|1) ;;
    *) fail "REMOVE_CONFIG debe ser 0 o 1" ;;
esac

if [ -z "$DESTDIR" ] && [ "$(id -u)" -ne 0 ]; then
    fail "la desinstalación real debe ejecutarse como root"
fi

BIN_DIR="$PREFIX/bin"
DOC_DIR="$PREFIX/share/doc/nut-telegram-monitor"

if [ -z "$DESTDIR" ] &&
    command -v systemctl >/dev/null 2>&1 &&
    [ -d /run/systemd/system ]
then
    systemctl disable --now ups-status-report.timer >/dev/null 2>&1 || true
    systemctl disable --now ups-startup-notify.service >/dev/null 2>&1 || true
    systemctl stop ups-status-report.service >/dev/null 2>&1 || true
fi

rm -f -- \
    "$(target_path "$BIN_DIR/notificar-ups-telegram")" \
    "$(target_path "$BIN_DIR/registrar-estado-ups")" \
    "$(target_path "$BIN_DIR/eventos-ups")" \
    "$(target_path "$SYSTEMD_UNIT_DIR/ups-startup-notify.service")" \
    "$(target_path "$SYSTEMD_UNIT_DIR/ups-status-report.service")" \
    "$(target_path "$SYSTEMD_UNIT_DIR/ups-status-report.timer")" \
    "$(target_path "$DOC_DIR/telegram.conf.example")" \
    "$(target_path "$DOC_DIR/upsmon.conf.snippet")" \
    "$(target_path "$DOC_DIR/README.md")" \
    "$(target_path "$DOC_DIR/LICENSE")"

DOC_TARGET=$(target_path "$DOC_DIR")

if [ -d "$DOC_TARGET" ]; then
    rmdir "$DOC_TARGET" 2>/dev/null || true
fi

CONFIG_TARGET=$(target_path "$SYSCONFDIR/telegram.conf")

if [ "$REMOVE_CONFIG" = 1 ]; then
    rm -f -- "$CONFIG_TARGET"
    printf 'Se eliminó la configuración: %s\n' "$CONFIG_TARGET"
elif [ -e "$CONFIG_TARGET" ]; then
    printf 'Se preservó la configuración: %s\n' "$CONFIG_TARGET"
fi

if [ -z "$DESTDIR" ]; then
    rm -f -- /run/nut/telegram-battery-last

    if command -v systemctl >/dev/null 2>&1 &&
        [ -d /run/systemd/system ]
    then
        systemctl daemon-reload
    fi
fi

printf '%s\n' \
    "Desinstalación de archivos completada." \
    "" \
    "Acción manual pendiente:" \
    "  Eliminá de /etc/nut/upsmon.conf las directivas agregadas para" \
    "  notificar-ups-telegram y reiniciá nut-monitor.service." \
    "" \
    "La configuración se conserva de forma predeterminada." \
    "Para eliminarla, usá REMOVE_CONFIG=1."