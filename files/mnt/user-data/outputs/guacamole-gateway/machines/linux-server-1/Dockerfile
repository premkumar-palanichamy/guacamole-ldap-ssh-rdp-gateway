# =============================================================================
# machines/linux-server-1/Dockerfile
#
# Builds a minimal Linux server container with SSH access.
#
# USE CASE: Bob (ssh-users group) connects via Guacamole → guacd → SSH → this container
#           The SSH session is authenticated using the NPA account (not Bob's LDAP creds).
#
# STACK: Ubuntu 22.04 → OpenSSH Server → NPA user
#
# WHY SO MINIMAL (no desktop, no GUI packages)?
#   This is a "server" — it's meant to be managed over the command line.
#   A desktop environment would add ~300MB for no benefit.
#   SSH server + shell is all that's needed for a terminal session via Guacamole.
# =============================================================================

FROM ubuntu:22.04

# Prevent apt from prompting for timezone/keyboard during package installation
ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# STEP 1: Install OpenSSH server
#
# openssh-server: the SSH daemon (sshd) that accepts incoming connections
# sudo: allows the npa user to run privileged commands if needed in the session
#
# WHY openssh-server and not dropbear?
#   OpenSSH is the standard SSH implementation on Ubuntu with full feature support.
#   Guacamole's SSH module is tested against OpenSSH.
#   dropbear is more minimal but less compatible with some SSH features.
# =============================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# STEP 2: Configure the SSH daemon
#
# /etc/ssh/sshd_config is the main OpenSSH configuration file.
# We modify two settings from their defaults:
#
# PasswordAuthentication yes:
#   Enables password-based login (as opposed to key-based only).
#   We NEED this because Guacamole sends the NPA's password to sshd.
#   The default in newer Ubuntu images is "prohibit-password" (keys only).
#   Without this change, sshd rejects the NPA's password and connection fails.
#
# PermitRootLogin no:
#   Disallows direct root login via SSH — security best practice.
#   The NPA user has a standard shell. If admin access is needed, use sudo.
#
# sed -i: modifies the file in-place
# The regex s|old|new| uses | as delimiter to avoid escaping /
# =============================================================================
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication prohibit-password/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# =============================================================================
# STEP 3: Create the SSH host key directory
#
# sshd requires /var/run/sshd to exist at runtime to place its PID file
# and to hold runtime state. This directory is NOT created by the package
# installer in some Ubuntu versions — we create it explicitly to avoid
# "Missing privilege separation directory: /var/run/sshd" errors.
# =============================================================================
RUN mkdir -p /var/run/sshd

# =============================================================================
# STEP 4: Create the NPA (Non-Personal Account) user
#
# The NPA account is the shared service account that Guacamole uses to log
# into this machine. The human user (Bob) never knows this password.
#
# useradd -m: create home directory (/home/npa)
# useradd -s /bin/bash: set shell to bash (required for interactive SSH sessions)
# chpasswd: set the password (hashed via crypt(), not stored in plaintext)
#
# This password matches the 'password' parameter in 02_data.sql for SSH connections.
# If you change it here, change it in 02_data.sql too, and vice versa.
# =============================================================================
RUN useradd -m -s /bin/bash npa && \
    echo "npa:npa_secure_password" | chpasswd

# =============================================================================
# EXPOSE 22 — SSH standard port
#
# Documents that this container accepts SSH connections on port 22.
# NOT published to the host — only guacd (inside guac-net) needs to reach it.
# =============================================================================
EXPOSE 22

# =============================================================================
# CMD: Run sshd in the foreground
#
# /usr/sbin/sshd -D: the SSH daemon in non-daemonizing mode
#   -D flag: "do not detach" — stays in the foreground, keeps container alive
#
# Without -D, sshd forks to background, this CMD returns exit 0, and Docker
# stops the container thinking the process finished.
#
# Array form ["cmd", "arg"]: exec form — no shell wrapper, signals go directly
# to sshd (clean shutdown on 'docker stop').
# =============================================================================
CMD ["/usr/sbin/sshd", "-D"]
