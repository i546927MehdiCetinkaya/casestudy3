# Kasm-based Workspace Base Image
# Uses kasmweb/core-ubuntu-jammy as base for browser-based desktop
FROM kasmweb/core-ubuntu-jammy:1.15.0

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=/dockerstartup/install
WORKDIR $HOME

# Install common tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    dnsutils \
    iputils-ping \
    openssh-client \
    ca-certificates \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# AD/LDAP integration packages (for future use)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ldap-utils \
    libpam-ldap \
    libnss-ldap \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
RUN mkdir -p /home/kasm-user/workspace && \
    chown -R 1000:1000 /home/kasm-user/workspace

# Environment variables for department customization
ENV DEPARTMENT=""
ENV EMPLOYEE_ID=""
ENV EMPLOYEE_EMAIL=""
ENV AD_DOMAIN="innovatech.local"

# Copy startup customization script
COPY startup-custom.sh /dockerstartup/startup-custom.sh
RUN chmod +x /dockerstartup/startup-custom.sh

USER 1000

ENTRYPOINT ["/dockerstartup/kasm_default_profile.sh", "/dockerstartup/vnc_startup.sh", "/dockerstartup/kasm_startup.sh"]
