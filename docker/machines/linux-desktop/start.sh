#!/usr/bin/env bash
set -euo pipefail

# Run cleanup of orphaned home directories
/usr/local/bin/cleanup_home_dirs.sh

rm -f /var/run/xrdp/xrdp.pid /var/run/xrdp/xrdp-sesman.pid /tmp/.X*-lock
mkdir -p /var/run/dbus

if ! pgrep -x dbus-daemon > /dev/null; then
  dbus-daemon --system --nofork --nopidfile &
  sleep 2
fi

/usr/sbin/xrdp-sesman --nodaemon &
sleep 1
exec /usr/sbin/xrdp --nodaemon
