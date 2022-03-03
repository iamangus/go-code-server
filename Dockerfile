FROM debian:11

RUN apt-get update \
 && apt-get install -y \
    curl \
    dumb-init \
    zsh \
    htop \
    locales \
    man \
    nano \
    git \
    git-lfs \
    build-essential \
    procps \
    openssh-client \
    sudo \
    vim.tiny \
    lsb-release \
  && git lfs install \
  && rm -rf /var/lib/apt/lists/*

# https://wiki.debian.org/Locale#Manually
RUN sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen \
  && locale-gen
ENV LANG=en_US.UTF-8

RUN adduser --gecos '' --disabled-password coder && \
  echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-$ARCH.tar.gz" | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

RUN curl -fsSL https://code-server.dev/install.sh | sh

WORKDIR /tmp/

RUN curl -O https://storage.googleapis.com/golang/go1.17.7.linux-amd64.tar.gz \
 && tar -xvf go1.17.7.linux-amd64.tar.gz \
 && sudo chown -R root:coder ./go \
 && sudo mv go /usr/local
 
RUN /usr/local/go/bin/go install golang.org/x/tools/gopls@latest
 
COPY entrypoint.sh /usr/bin/entrypoint.sh

RUN sudo chmod +x /usr/bin/entrypoint.sh

COPY .bashrc /tmp/.bashrc
 
EXPOSE 8080
# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER 1000
ENV USER=coder
WORKDIR /home/coder/go

ENV PASSWORD=""
ENV GH_TOKEN=""
ENV GH_REPO=""

RUN ls -ltra /home/coder

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]
