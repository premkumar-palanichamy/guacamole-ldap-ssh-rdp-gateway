FROM ubuntu:22.04

# Set noninteractive mode for package installation
ENV DEBIAN_FRONTEND=noninteractive

# Pre-answer slapd configuration prompts
RUN echo "slapd slapd/password1 password admin123" | debconf-set-selections && \
    echo "slapd slapd/password2 password admin123" | debconf-set-selections && \
    echo "slapd slapd/domain string ladvik.local" | debconf-set-selections

# Install OpenLDAP server and utilities
RUN apt-get update && apt-get install -y \
    slapd \
    ldap-utils \
    debconf-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy LDAP groups configuration
# Note: slapd.conf is not used; configuration is set via debconf during package install
COPY docker/openldap/groups.ldif /ldifs/groups.ldif
COPY docker/openldap/entrypoint.sh /entrypoint.sh

# Create directories and set permissions
RUN mkdir -p /var/lib/ldap /var/run/slapd /ldifs && \
    chown -R openldap:openldap /var/lib/ldap /var/run/slapd && \
    chmod 755 /ldifs && \
    chmod +x /entrypoint.sh

# Expose LDAP port
EXPOSE 389

# Run entrypoint
ENTRYPOINT ["/entrypoint.sh"]
