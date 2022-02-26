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
 
COPY entrypoint.sh /usr/bin/entrypoint.sh
 
EXPOSE 8080
# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER 1000
ENV USER=coder
WORKDIR /home/coder
RUN mkdir go

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]
