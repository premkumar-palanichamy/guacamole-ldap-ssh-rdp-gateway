FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server ca-certificates ldap-utils libpam-modules \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd

# Enable automatic home directory creation on first login
RUN echo "session required pam_mkhomedir.so umask=0022" >> /etc/pam.d/common-session

RUN useradd -m -s /bin/bash target \
    && echo 'target:Target@123' | chpasswd

COPY sshd_config /etc/ssh/sshd_config
COPY start.sh /start.sh
COPY cleanup_home_dirs.sh /usr/local/bin/cleanup_home_dirs.sh
RUN chmod +x /start.sh /usr/local/bin/cleanup_home_dirs.sh

EXPOSE 22

CMD ["/start.sh"]
