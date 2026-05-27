FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-goodies \
        xrdp \
        xorgxrdp \
        dbus-x11 \
        sudo \
        ca-certificates \
        ldap-utils \
        libpam-modules \
    && rm -rf /var/lib/apt/lists/*

# Enable automatic home directory creation on first login
RUN echo "session required pam_mkhomedir.so umask=0022" >> /etc/pam.d/common-session

RUN useradd -m -s /bin/bash desktop \
    && echo 'desktop:Desktop@123' | chpasswd \
    && adduser desktop sudo \
    && usermod -aG ssl-cert xrdp \
    && printf 'startxfce4\n' > /etc/skel/.xsession \
    && cp /etc/skel/.xsession /home/desktop/.xsession \
    && chown desktop:desktop /home/desktop/.xsession

COPY start.sh /start.sh
COPY cleanup_home_dirs.sh /usr/local/bin/cleanup_home_dirs.sh
RUN chmod +x /start.sh /usr/local/bin/cleanup_home_dirs.sh

EXPOSE 3389

CMD ["/start.sh"]
