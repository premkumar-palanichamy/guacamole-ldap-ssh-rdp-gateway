#!/usr/bin/env bash
set -euo pipefail

rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid
mkdir -p /var/run/dbus

if ! pgrep -x dbus-daemon > /dev/null; then
  dbus-daemon --system
fi

/usr/sbin/xrdp-sesman --nodaemon &
exec /usr/sbin/xrdp --nodaemon
