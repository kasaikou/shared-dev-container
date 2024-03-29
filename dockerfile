ARG baseimage=ubuntu:22.04
ARG apt_mirror=archive.ubuntu.com

FROM ${baseimage} AS core
ARG apt_mirror
RUN sed -i "s@archive.ubuntu.com@${apt_mirror}@g" /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg \
    software-properties-common \
    sudo \
    unzip \
    wget

RUN \
    # docker
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo deb "[arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # gh
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    # terraform
    wget -qO- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list && \
    # unity
    wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null && \
    sh -c 'echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list' && \
    # google chrome
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrom-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | \
    tee /etc/apt/sources.list.d/google-chrome.list && \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrom-keyring.gpg

RUN export DEBIAN_FRONTEND=nointeractive && \
    apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    chromium-browser \
    chromium-browser-l10n \
    chromium-codecs-ffmpeg \
    clang-format \
    docker-ce-cli \
    file \
    fonts-ipaexfont-mincho \
    gcc \
    gh \
    ghostscript \
    gir1.2-gtk-4.0 \
    gobject-introspection \
    google-chrome-stable \
    gdk-pixbuf-2.0-dev \
    gtk-doc-tools \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libayatana-appindicator3-dev \
    libcairo2 \
    libcairo2-dev \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libgirepository1.0-dev \
    libgl1-mesa-dev \
    libgladeui-dev \
    libglib2.0-0 \
    libgtk-3-dev \
    libnss3 \
    libpango-1.0-0 \
    librsvg2-dev \
    librust-atk-dev \
    libsoup2.4-dev \
    libssl-dev \
    libtool \
    libwebkit2gtk-4.0-dev \
    libx11-dev \
    libxcomposite1 \
    libxcursor-dev \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    pkg-config \
    pinentry-qt \
    poppler-utils \
    python3-dev \
    python3-distutils \
    terraform \
    unityhub \
    x11-apps \
    xorg-dev

ARG go=1.21.3
ARG protobuf=25.2

RUN \
    # docker compose
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -SL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose && \
    # go
    wget -qO go.tar.gz "https://go.dev/dl/go${go}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf go.tar.gz && \
    export PATH=${PATH}:/usr/local/go/bin && \
    rm -rf go.tar.gz && \
    export GOBIN=/usr/local/bin && \
    # protocol buffers
    curl -OL https://github.com/google/protobuf/releases/download/v${protobuf}/protoc-${protobuf}-linux-x86_64.zip && \
    unzip protoc-${protobuf}-linux-x86_64.zip -d protobuf && \
    mv protobuf/bin/* /usr/local/bin/ && \
    mv protobuf/include/* /usr/local/include/ && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2 && \
    go install github.com/go-task/task/v3/cmd/task@latest && \
    go install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@latest && \
    # act
    curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | bash

ENV PATH=${PATH}:/usr/local/go/bin

ARG user=container
ARG uid=1000
ARG gid=1000

RUN groupadd --gid ${gid} ${user} && \
    useradd -s /bin/bash --uid ${uid} --gid ${gid} -m ${user} && \
    echo ${user} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${user} && \
    chmod 0440 /etc/sudoers.d/${user}

USER ${user}

RUN \
    # poetry
    curl -sSL https://install.python-poetry.org | python3 - --version 1.6.1 && \
    # rust
    curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y && \
    # homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    export PATH=/home/linuxbrew/.linuxbrew/bin:${PATH} && \
    # nodenv and yarn
    brew install nodenv && \
    mkdir -p "$(nodenv root)/plugins" && \
    git clone https://github.com/pine/nodenv-yarn-install.git "$(nodenv root)/plugins/nodenv-yarn-install" && \
    nodenv install 18.19.0 && \
    nodenv global 18.19.0 && \
    nodenv rehash && \
    export PATH=/home/${user}/.nodenv/shims:${PATH} && \
    # press-ready
    yarn global add press-ready


ENV PATH=${PATH}:/home/linuxbrew/.linuxbrew/bin
