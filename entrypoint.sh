#!/bin/bash
set -eu

# We do this first to ensure sudo works below when renaming the user.
# Otherwise the current container UID may not exist in the passwd database.
eval "$(fixuid -q)"

if [ "${DOCKER_USER-}" ]; then
  USER="$DOCKER_USER"
  if [ "$DOCKER_USER" != "$(whoami)" ]; then
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd > /dev/null
    # Unfortunately we cannot change $HOME as we cannot move any bind mounts
    # nor can we bind mount $HOME into a new home as that requires a privileged container.
    sudo usermod --login "$DOCKER_USER" coder
    sudo groupmod -n "$DOCKER_USER" coder

    sudo sed -i "/coder/d" /etc/sudoers.d/nopasswd
  fi
fi

if [[ -z "${GH_REPO}" ]]; then
  echo "No github repo provided. Nothing to clone."
else
  echo "Found github repo. Checking for a github personal access token."
  if [[ -z "${GH_TOKEN}" ]]; then
    echo "No github token provided. Cloning public repo."
    sudo git clone $GH_REPO
  else
    echo "found a github token. Cloning repo."
    sudo git clone $GH_TOKEN@$GH_REPO
  fi
fi

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

go get golang.org/x/tools/gopls@latest

cp /tmp/.bashrc /home/coder/.bashrc
ls -ltra /home/coder

dumb-init /usr/bin/code-server "$@"
