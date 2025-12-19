# Infrastructure Department Workspace
# Tools: PuTTY, WinSCP, VS Code, Network utilities, AWS CLI
FROM kasmweb/core-ubuntu-jammy:1.15.0

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

# Disable KasmVNC Basic Auth - use token-based authentication instead
ENV KASM_BASIC_AUTH_DISABLED=1
ENV KASM_VNC_NO_AUTH_WARNING=true

# Common utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    jq \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Network and Infrastructure tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools \
    dnsutils \
    iputils-ping \
    traceroute \
    nmap \
    tcpdump \
    wireshark \
    iftop \
    openssh-client \
    telnet \
    netcat-openbsd \
    mtr \
    iperf3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PuTTY and related tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    putty \
    putty-tools \
    filezilla \
    remmina \
    remmina-plugin-rdp \
    remmina-plugin-vnc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get install -y code && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    && pip3 install ansible boto3 botocore \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# LDAP utilities for AD integration
RUN apt-get update && apt-get install -y --no-install-recommends \
    ldap-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directory
RUN mkdir -p /home/kasm-user/workspace /home/kasm-user/Desktop && \
    chown -R 1000:1000 /home/kasm-user

# Copy department-specific branding
COPY infra-startup.sh /dockerstartup/custom_startup.sh
RUN chmod +x /dockerstartup/custom_startup.sh

# Environment
ENV DEPARTMENT="infrastructure"
ENV AD_DOMAIN="innovatech.local"

USER 1000

# Default command
CMD ["/dockerstartup/kasm_default_profile.sh", "/dockerstartup/vnc_startup.sh", "/dockerstartup/kasm_startup.sh"]
