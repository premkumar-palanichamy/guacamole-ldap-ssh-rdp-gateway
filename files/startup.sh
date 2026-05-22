#!/bin/bash
# =============================================================================
# startup.sh — Container entrypoint for linux-desktop
#
# This script is PID 1 inside the container. It:
#   1. Cleans up stale lock files from previous container runs
#   2. Starts the D-Bus system daemon (required by Xfce4)
#   3. Starts xrdp-sesman (the XRDP session manager)
#   4. Starts xrdp in the foreground (keeps the container alive)
#
# WHY NOT USE supervisord?
#   supervisord is a full process supervisor with config files, restart policies,
#   and HTTP management. For 3 simple sequential processes, a bash script is
#   lighter and easier to understand. supervisord is installed in the image
#   as a troubleshooting tool if needed.
#
# WHY exec for the final process?
#   exec REPLACES the current shell with the new process.
#   Without exec: bash is PID 1, xrdp is a child. SIGTERM goes to bash,
#   xrdp doesn't receive it, Docker has to SIGKILL after timeout.
#   With exec: xrdp IS PID 1. SIGTERM goes directly to xrdp, clean shutdown.
# =============================================================================

set -e  # exit immediately if any command fails

echo "[startup] Starting linux-desktop container..."

# =============================================================================
# STEP 1: Clean up D-Bus stale PID file
#
# If the container was previously running and was killed (not gracefully stopped),
# dbus-daemon leaves behind /run/dbus/pid with the old PID.
# On restart, dbus-daemon checks this file and refuses to start if it exists
# (it thinks another instance is running).
#
# mkdir -p: creates /run/dbus if it doesn't exist (fresh container start)
# rm -f: removes the PID file if it exists, silently if it doesn't (-f flag)
# =============================================================================
echo "[startup] Cleaning up stale lock files..."
mkdir -p /run/dbus
rm -f /run/dbus/pid

# =============================================================================
# STEP 2: Clean up stale X11 lock files
#
# X11 creates /tmp/.X<display>-lock files to track running display servers.
# Inside a container, display :0 is typically used.
# Stale lock files prevent new X sessions from starting with the same display number.
# The wildcard /tmp/.X*-lock removes any display lock file.
# =============================================================================
rm -f /tmp/.X*-lock

# =============================================================================
# STEP 3: Start D-Bus system daemon
#
# D-Bus is an inter-process communication (IPC) system.
# Xfce4 uses D-Bus for:
#   - Desktop notifications
#   - Power management events
#   - Communication between Xfce4 components
#
# Without D-Bus, Xfce4 either crashes or shows errors on startup.
#
# dbus-daemon flags:
#   --system      : start as system bus (not session bus — that starts per-session)
#   --nofork      : don't background (we background it ourselves with &)
#   --nopidfile   : don't write a PID file (we already cleaned any stale one)
#
# & : run in background so this script continues
# sleep 2 : give D-Bus time to fully initialize before starting XRDP
# =============================================================================
echo "[startup] Starting D-Bus..."
dbus-daemon --system --nofork --nopidfile &
sleep 2

# =============================================================================
# STEP 4: Start XRDP session manager (xrdp-sesman)
#
# xrdp-sesman manages user sessions:
#   - Authenticates users (checks Linux PAM → validates npa password)
#   - Creates virtual X displays for each session
#   - Runs the session startup script (/etc/xrdp/startwm.sh → xfce4-session)
#   - Tracks and cleans up sessions when users disconnect
#
# xrdp-sesman must start BEFORE xrdp because xrdp connects to sesman
# to hand off authenticated sessions.
#
# & : background it (not the final process)
# sleep 1 : brief pause to ensure sesman's socket is ready
# =============================================================================
echo "[startup] Starting XRDP session manager..."
/usr/sbin/xrdp-sesman &
sleep 1

# =============================================================================
# STEP 5: Start XRDP daemon (foreground — this keeps the container alive)
#
# xrdp is the main RDP server daemon. It:
#   - Listens on TCP port 3389 for incoming RDP connections
#   - Handles the RDP protocol handshake
#   - Forwards authenticated sessions to xrdp-sesman
#   - Streams the desktop back to the RDP client (guacd)
#
# --nodaemon : run in the FOREGROUND (don't daemonize)
#              Without this, xrdp forks to background and this script exits,
#              causing Docker to think the container has stopped.
#
# exec : replace this bash process with xrdp (so xrdp becomes PID 1)
#        SIGTERM from 'docker stop' goes directly to xrdp for clean shutdown
# =============================================================================
echo "[startup] Starting XRDP (foreground)..."
exec /usr/sbin/xrdp --nodaemon
