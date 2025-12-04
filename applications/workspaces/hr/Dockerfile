# HR Department Workspace
# Tools: Browser, Office Suite (LibreOffice), PDF tools
FROM kasmweb/core-ubuntu-jammy:1.15.0

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

# Common utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    vim \
    nano \
    unzip \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Firefox browser
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Chromium browser
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium-browser \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install LibreOffice suite
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-calc \
    libreoffice-writer \
    libreoffice-impress \
    libreoffice-draw \
    libreoffice-base \
    libreoffice-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PDF tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    evince \
    pdfarranger \
    poppler-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install file management and utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    thunar \
    file-roller \
    gnome-calculator \
    gedit \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install email client
RUN apt-get update && apt-get install -y --no-install-recommends \
    thunderbird \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create workspace directories
RUN mkdir -p /home/kasm-user/workspace \
    /home/kasm-user/Desktop \
    /home/kasm-user/Documents \
    /home/kasm-user/Downloads && \
    chown -R 1000:1000 /home/kasm-user

# Copy department-specific branding
COPY hr-wallpaper.png /usr/share/backgrounds/hr-wallpaper.png
COPY hr-startup.sh /dockerstartup/custom_startup.sh
RUN chmod +x /dockerstartup/custom_startup.sh

# Environment
ENV DEPARTMENT="hr"
ENV AD_DOMAIN="innovatech.local"

USER 1000

# Default command
CMD ["/dockerstartup/kasm_default_profile.sh", "/dockerstartup/vnc_startup.sh", "/dockerstartup/kasm_startup.sh"]
