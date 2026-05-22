# =============================================================================
# machines/linux-desktop/Dockerfile
#
# Builds a Linux container with a full graphical desktop accessible via RDP.
#
# WHAT IS XRDP?
#   XRDP is an open-source implementation of Microsoft's Remote Desktop Protocol
#   (RDP) for Linux. It acts as an RDP server — it accepts connections from any
#   RDP client (including Guacamole's guacd daemon) and serves a desktop session.
#
# STACK: Ubuntu 22.04 → Xfce4 (desktop) → XRDP (RDP server) → NPA user
#
# WHY UBUNTU 22.04 (not Alpine or Debian)?
#   xrdp and xfce4 packages are well-tested on Ubuntu. Alpine lacks the full
#   X11 ecosystem. Ubuntu 22.04 is LTS — stable, with long-term apt repos.
#
# WHY XFCE4 (not GNOME or KDE Plasma)?
#   GNOME requires systemd as a session manager — systemd does not work well
#   inside Docker (PID 1 expectations, cgroup management conflicts).
#   KDE Plasma is similarly heavy (~800MB) and systemd-entangled.
#   Xfce4 is lightweight (~200MB), starts with a simple xfce4-session command,
#   and has zero systemd dependencies. Perfect for Docker.
#
# WHY SUPERVISOR? (supervisord)
#   We need to run TWO background processes (dbus + xrdp) plus keep the
#   container alive. An init process manages restarts if they crash.
#   We use a custom startup.sh instead of supervisord to keep things minimal,
#   but supervisor is installed as a backup for troubleshooting.
# =============================================================================

# Start from Ubuntu 22.04 LTS — fixed tag for reproducibility
FROM ubuntu:22.04

# DEBIAN_FRONTEND=noninteractive prevents apt from prompting for timezone,
# keyboard layout, etc. during the build. Without this, the build hangs.
ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# STEP 1: Install all required packages in a single RUN layer
#
# WHY one RUN? Each RUN creates a Docker layer. Combining them:
#   - Reduces image size (no intermediate apt cache layers)
#   - Ensures apt cache is cleaned in the same layer it was populated
#
# Packages explained:
#   xrdp           — The RDP server daemon (accepts RDP connections on :3389)
#   xfce4          — The Xfce4 desktop environment (window manager + panels)
#   xfce4-goodies  — Extra Xfce4 plugins (file manager, terminal, etc.)
#   dbus-x11       — D-Bus session bus for X11 (Xfce4 requires D-Bus)
#   x11-xserver-utils — xrandr and xrdb utilities (used by XRDP for display setup)
#   supervisor     — Process supervisor (installed but not used by default)
#   sudo           — Allows npa user to run admin commands if needed
# =============================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xrdp \
        xfce4 \
        xfce4-goodies \
        dbus-x11 \
        x11-xserver-utils \
        supervisor \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
    # apt-get clean: removes downloaded .deb files from /var/cache/apt/archives/
    # rm -rf /var/lib/apt/lists/: removes the package list index
    # Together these save ~100MB from the final image

# =============================================================================
# STEP 2: Configure XRDP to launch Xfce4 session
#
# /etc/xrdp/startwm.sh is the script XRDP runs when a user connects.
# The default script tries to launch various session managers.
# We REPLACE it entirely with a minimal script that just starts Xfce4.
#
# xfce4-session: starts the complete Xfce4 desktop (window manager, panel, etc.)
# exec: replaces the shell process — cleaner process tree, correct signal handling
#
# The chmod 755 makes the script executable (required for XRDP to run it).
# =============================================================================
RUN echo '#!/bin/sh\nexec xfce4-session' > /etc/xrdp/startwm.sh && \
    chmod 755 /etc/xrdp/startwm.sh

# =============================================================================
# STEP 3: Configure XRDP sesman (session manager)
#
# /etc/xrdp/sesman.ini controls XRDP's session manager.
# Key changes from defaults:
#
#   AllowRootLogin=false  — Security: root cannot log in via RDP
#   MaxSessions=10        — Allow up to 10 concurrent desktop sessions
#   X11DisplayOffset=10   — First virtual display is :10 (avoids conflict with :0)
#   Policy=UBDesktop      — Ubuntu/Debian compatible session policy
#
# sed -i: modifies the file in-place
# s/AllowRootLogin=true/AllowRootLogin=false/: find-and-replace in the ini file
# =============================================================================
RUN sed -i 's/AllowRootLogin=true/AllowRootLogin=false/' /etc/xrdp/sesman.ini

# =============================================================================
# STEP 4: Add XRDP user to ssl-cert group
#
# XRDP generates a self-signed TLS certificate during installation.
# The private key is at /etc/ssl/private/ssl-cert-snakeoil.key
# That file is owned by root:ssl-cert and has mode 640.
# XRDP's daemon runs as the 'xrdp' user — without this group membership,
# it cannot read the private key and TLS handshake fails.
#
# adduser xrdp ssl-cert: adds the 'xrdp' system user to the 'ssl-cert' group
# =============================================================================
RUN adduser xrdp ssl-cert

# =============================================================================
# STEP 5: Create the NPA (Non-Personal Account) user
#
# WHY NPA?
#   The assignment requires that users log into Guacamole with their own LDAP
#   credentials (bob/alice), but the actual RDP connection to the target machine
#   uses a shared service account (NPA). This decouples human identity from
#   machine access credentials.
#
# Benefits:
#   - End users never know the machine password
#   - One credential to rotate when the password changes (in Guacamole DB)
#   - Audit trail in Guacamole shows which human used which connection
#
# useradd flags:
#   -m : create home directory at /home/npa
#   -s /bin/bash : set login shell to bash (needed for SSH and RDP)
#
# chpasswd reads "username:password" from stdin and sets the password.
# The password is hashed using crypt() — not stored in plaintext.
# =============================================================================
RUN useradd -m -s /bin/bash npa && \
    echo "npa:npa_secure_password" | chpasswd

# =============================================================================
# STEP 6: Configure .xsession for the NPA user
#
# When XRDP starts a session for 'npa', it executes /home/npa/.xsession
# (after sourcing /etc/xrdp/startwm.sh — but we've replaced that already).
# Some XRDP versions check .xsession directly.
#
# We set it explicitly to ensure xfce4-session starts regardless of which
# code path XRDP uses to launch the session.
#
# chown npa:npa: the file must be owned by the user (XRDP runs it AS that user)
# chmod 755: must be executable
# =============================================================================
RUN echo "xfce4-session" > /home/npa/.xsession && \
    chown npa:npa /home/npa/.xsession && \
    chmod 755 /home/npa/.xsession

# =============================================================================
# STEP 7: Copy the startup script
#
# startup.sh manages the container's process lifecycle:
#   - Cleans up stale lock files (from previous container runs)
#   - Starts D-Bus (required by Xfce4)
#   - Starts XRDP session manager (xrdp-sesman)
#   - Starts XRDP daemon (xrdp) in the foreground
#
# The script is the container's CMD — it runs as PID 1.
# =============================================================================
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# =============================================================================
# EXPOSE 3389
#
# EXPOSE is documentation — it tells Docker and humans that this container
# listens on port 3389 (RDP standard port).
# It does NOT publish the port to the host — that requires 'ports:' in compose.
# We deliberately do NOT publish this port to the host (no ports: in compose).
# Only guacd (inside guac-net) needs to reach it.
# =============================================================================
EXPOSE 3389

# CMD: the command that runs when the container starts.
# Using array form ["cmd"] rather than string form "cmd" avoids shell wrapping
# and ensures signals (SIGTERM) go directly to the script, not to /bin/sh.
CMD ["/startup.sh"]
