# Development Department Workspace
# Tools: VS Code, Git, Docker, Node.js, Python, Java
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
    build-essential \
    ca-certificates \
    gnupg \
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

# Install Node.js 20.x LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest yarn pnpm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python 3 with development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && pip3 install --upgrade pip \
    && pip3 install virtualenv pytest black flake8 mypy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Java 17 (OpenJDK)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    maven \
    gradle \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for docker-in-docker or remote docker)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Git and related tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs \
    gitk \
    meld \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl for Kubernetes development
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Database clients
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    mysql-client \
    redis-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# API testing tools (httpie via apt, newman via npm)
RUN npm install -g newman

# Create workspace directory
RUN mkdir -p /home/kasm-user/workspace /home/kasm-user/Desktop /home/kasm-user/projects && \
    chown -R 1000:1000 /home/kasm-user

# Copy department-specific branding
COPY dev-startup.sh /dockerstartup/custom_startup.sh
RUN chmod +x /dockerstartup/custom_startup.sh

# Environment
ENV DEPARTMENT="development"
ENV AD_DOMAIN="innovatech.local"
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

USER 1000

# Default command
CMD ["/dockerstartup/kasm_default_profile.sh", "/dockerstartup/vnc_startup.sh", "/dockerstartup/kasm_startup.sh"]
