# =============================================================================
# machines/linux-server-2/Dockerfile
#
# Identical to linux-server-1 — a second SSH target machine.
#
# WHY have two identical SSH servers?
#   The assignment requires 2 SSH machines to demonstrate that Bob can access
#   MULTIPLE machines from the same ssh-users group permission grant.
#   In a real scenario, these would be different servers with different purposes
#   (e.g., web-server-1, db-server-1), but for this playground they're the same image.
#
# In production, you would:
#   1. Give each machine a meaningful name and hostname
#   2. Potentially have different NPA accounts per machine (or per environment)
#   3. Use SSH key authentication instead of passwords
#
# See linux-server-1/Dockerfile for detailed line-by-line comments.
# All logic here is identical — comments kept brief to avoid duplication.
# =============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable password authentication and disable root login
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication prohibit-password/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Required runtime directory for sshd
RUN mkdir -p /var/run/sshd

# Create the NPA service account (must match password in 02_data.sql)
RUN useradd -m -s /bin/bash npa && \
    echo "npa:npa_secure_password" | chpasswd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
