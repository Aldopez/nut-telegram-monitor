#!/bin/sh

set -eu

PROJECT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

DESTDIR="${DESTDIR:-}"
PREFIX="${PREFIX:-/usr/local}"
SYSCONFDIR="${SYSCONFDIR:-/etc/nut}"
SYSTEMD_UNIT_DIR="${SYSTEMD_UNIT_DIR:-/etc/systemd/system}"

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

target_path() {
    printf '%s%s\n' "$DESTDIR" "$1"
}

ensure_dir() {
    directory=$(target_path "$1")
    mode=$2

    if [ ! -d "$directory" ]; then
        install -d -m "$mode" "$directory"
    fi
}

case "$DESTDIR" in
    ''|/*) ;;
    *) fail "DESTDIR debe ser una ruta absoluta" ;;
esac

case "$PREFIX:$SYSCONFDIR:$SYSTEMD_UNIT_DIR" in
    /*:/*:/*) ;;
    *) fail "PREFIX, SYSCONFDIR y SYSTEMD_UNIT_DIR deben ser rutas absolutas" ;;
esac

if [ -z "$DESTDIR" ] && [ "$(id -u)" -ne 0 ]; then
    fail "la instalación real debe ejecutarse como root"
fi

if [ -z "$DESTDIR" ] && ! getent group nut >/dev/null 2>&1; then
    fail "no existe el grupo nut; instalá y configurá NUT primero"
fi

BIN_DIR="$PREFIX/bin"
DOC_DIR="$PREFIX/share/doc/nut-telegram-monitor"

ensure_dir "$BIN_DIR" 755
ensure_dir "$DOC_DIR" 755
ensure_dir "$SYSCONFDIR" 755
ensure_dir "$SYSTEMD_UNIT_DIR" 755

install -m 755 \
    "$PROJECT_DIR/bin/notificar-ups-telegram" \
    "$(target_path "$BIN_DIR/notificar-ups-telegram")"

install -m 755 \
    "$PROJECT_DIR/bin/registrar-estado-ups" \
    "$(target_path "$BIN_DIR/registrar-estado-ups")"

install -m 755 \
    "$PROJECT_DIR/bin/eventos-ups" \
    "$(target_path "$BIN_DIR/eventos-ups")"

install -m 644 \
    "$PROJECT_DIR/systemd/ups-startup-notify.service" \
    "$(target_path "$SYSTEMD_UNIT_DIR/ups-startup-notify.service")"

install -m 644 \
    "$PROJECT_DIR/systemd/ups-status-report.service" \
    "$(target_path "$SYSTEMD_UNIT_DIR/ups-status-report.service")"

install -m 644 \
    "$PROJECT_DIR/systemd/ups-status-report.timer" \
    "$(target_path "$SYSTEMD_UNIT_DIR/ups-status-report.timer")"

install -m 644 \
    "$PROJECT_DIR/config/telegram.conf.example" \
    "$(target_path "$DOC_DIR/telegram.conf.example")"

install -m 644 \
    "$PROJECT_DIR/config/upsmon.conf.snippet" \
    "$(target_path "$DOC_DIR/upsmon.conf.snippet")"

install -m 644 \
    "$PROJECT_DIR/README.md" \
    "$PROJECT_DIR/LICENSE" \
    "$(target_path "$DOC_DIR")"

CONFIG_TARGET=$(target_path "$SYSCONFDIR/telegram.conf")

if [ -e "$CONFIG_TARGET" ]; then
    printf 'Se preservó la configuración existente: %s\n' "$CONFIG_TARGET"
else
    if [ -z "$DESTDIR" ]; then
        install -o root -g nut -m 640 \
            "$PROJECT_DIR/config/telegram.conf.example" \
            "$CONFIG_TARGET"
    else
        install -m 640 \
            "$PROJECT_DIR/config/telegram.conf.example" \
            "$CONFIG_TARGET"
    fi

    printf 'Se creó la configuración inicial: %s\n' "$CONFIG_TARGET"
fi

if [ -z "$DESTDIR" ] &&
    command -v systemctl >/dev/null 2>&1 &&
    [ -d /run/systemd/system ]
then
    systemctl daemon-reload
fi

printf '%s\n' \
    "Instalación de archivos completada." \
    "" \
    "Pasos pendientes:" \
    "  1. Editar $SYSCONFDIR/telegram.conf." \
    "  2. Integrar $DOC_DIR/upsmon.conf.snippet en /etc/nut/upsmon.conf." \
    "  3. Reiniciar nut-monitor después de validar su configuración." \
    "  4. Habilitar los servicios solamente después de realizar las pruebas."