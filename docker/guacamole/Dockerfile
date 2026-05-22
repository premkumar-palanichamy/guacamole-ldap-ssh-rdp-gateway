ARG GUACAMOLE_VERSION=1.5.5
FROM guacamole/guacamole:${GUACAMOLE_VERSION}

LABEL org.opencontainers.image.title="guacamole-web" \
      org.opencontainers.image.description="Apache Guacamole web application image for LDAP-backed SSH/RDP gateway" \
      org.opencontainers.image.vendor="Ladvik" \
      org.opencontainers.image.source="local"

# ── Custom branding extension ──────────────────────────────────────────────────
USER root

RUN apt-get update && apt-get install -y --no-install-recommends zip \
    && rm -rf /var/lib/apt/lists/*

# Copy branding assets and create template structure
COPY docker/guacamole/branding/ /tmp/branding/

# Build the extension JAR
RUN mkdir -p /etc/guacamole/extensions && \
    cd /tmp/branding && \
    zip -r /etc/guacamole/extensions/custom-branding.jar . && \
    rm -rf /tmp/branding

# Create custom guacamole.properties with branding overrides
RUN echo "# Branding customization" > /etc/guacamole/guacamole.properties && \
    echo "# Default view preference (optional - users can change)" >> /etc/guacamole/guacamole.properties

USER guacamole
