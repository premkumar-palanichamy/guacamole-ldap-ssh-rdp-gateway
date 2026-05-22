FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LDAP_DOMAIN=ladvik.local
ENV LDAP_ORGANIZATION=Ladvik
ENV LDAP_ADMIN_PASSWORD=admin123

RUN apt-get update \
	&& apt-get install -y --no-install-recommends slapd ldap-utils ca-certificates tini \
	&& rm -rf /var/lib/apt/lists/*

# Configure slapd non-interactively.
RUN printf 'slapd slapd/no_configuration boolean false\n' | debconf-set-selections \
	&& printf 'slapd slapd/domain string %s\n' "$LDAP_DOMAIN" | debconf-set-selections \
	&& printf 'slapd shared/organization string %s\n' "$LDAP_ORGANIZATION" | debconf-set-selections \
	&& printf 'slapd slapd/password1 password %s\n' "$LDAP_ADMIN_PASSWORD" | debconf-set-selections \
	&& printf 'slapd slapd/password2 password %s\n' "$LDAP_ADMIN_PASSWORD" | debconf-set-selections \
	&& printf 'slapd slapd/backend select MDB\n' | debconf-set-selections \
	&& printf 'slapd slapd/purge_database boolean true\n' | debconf-set-selections \
	&& printf 'slapd slapd/move_old_database boolean true\n' | debconf-set-selections \
	&& dpkg-reconfigure -f noninteractive slapd

# Bundle LDAP schema and initial data into the image.
COPY ldap/bootstrap /bootstrap
COPY docker/ldap/start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 389

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]
