FROM codercom/code-server:4.0.2

RUN sudo apt-get update \
 && sudo apt-get install -y \
    build-essential \
 && sudo rm -rf /var/lib/apt/lists/*
  
WORKDIR /tmp/

RUN curl -O https://storage.googleapis.com/golang/go1.17.7.linux-amd64.tar.gz \
 && tar -xvf go1.17.7.linux-amd64.tar.gz \
 && sudo chown -R root:root ./go \
 && sudo mv go /usr/local
 
RUN sudo /usr/local/go/bin/go install golang.org/x/tools/gopls@latest

RUN sudo code-server --install-extension golang.go
 
COPY entrypoint.sh /usr/bin/entrypoint.sh

RUN sudo chmod +x /usr/bin/entrypoint.sh

COPY .bashrc /tmp/.bashrc

RUN mkdir /home/coder/go
# && sudo chown -R coder:coder /home/coder/
 
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
