# Employee Workspace - Linux Desktop with noVNC (XFCE in Browser)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=employee
ENV PASSWORD=changeme
ENV VNC_RESOLUTION=1920x1080
ENV VNC_PORT=5901
ENV NOVNC_PORT=6080

# Install desktop environment and VNC
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    supervisor \
    sudo \
    curl \
    wget \
    git \
    vim \
    nano \
    firefox \
    python3 \
    python3-pip \
    nodejs \
    npm \
    htop \
    net-tools \
    dbus-x11 \
    xfonts-base \
    xfonts-100dpi \
    xfonts-75dpi \
    fonts-liberation \
    fonts-dejavu \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER}:${PASSWORD}" | chpasswd && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup VNC
RUN mkdir -p /home/${USER}/.vnc && \
    echo '#!/bin/bash\nstartxfce4 &' > /home/${USER}/.vnc/xstartup && \
    chmod +x /home/${USER}/.vnc/xstartup && \
    chown -R ${USER}:${USER} /home/${USER}

# Create startup script
RUN echo '#!/bin/bash\n\
# Set VNC password from environment\n\
echo "${PASSWORD}" | vncpasswd -f > /home/${USER}/.vnc/passwd\n\
chmod 600 /home/${USER}/.vnc/passwd\n\
chown ${USER}:${USER} /home/${USER}/.vnc/passwd\n\
\n\
# Start VNC server\n\
su - ${USER} -c "vncserver :1 -geometry ${VNC_RESOLUTION} -depth 24"\n\
\n\
# Start noVNC (web-based VNC client)\n\
websockify --web=/usr/share/novnc/ ${NOVNC_PORT} localhost:${VNC_PORT} &\n\
\n\
# Keep container running\n\
tail -f /dev/null\n\
' > /startup.sh && chmod +x /startup.sh

# Create workspace directory
RUN mkdir -p /home/${USER}/workspace && chown -R ${USER}:${USER} /home/${USER}/workspace

WORKDIR /home/${USER}

EXPOSE 6080

CMD ["/startup.sh"]
