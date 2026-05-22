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
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash desktop \
    && echo 'desktop:Desktop@123' | chpasswd \
    && adduser desktop sudo \
    && usermod -aG ssl-cert xrdp \
    && printf 'startxfce4\n' > /etc/skel/.xsession \
    && cp /etc/skel/.xsession /home/desktop/.xsession \
    && chown desktop:desktop /home/desktop/.xsession

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
