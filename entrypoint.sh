#!/bin/bash
set -eu

sudo chown -R coder:coder /home/coder/go

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
  CODEDIR="."
else
  basename https://$GH_REPO
  CODEDIR=$(basename https://$GH_REPO)
  echo "Found github repo. Checking for a github personal access token."
  if [[ -z "${GH_TOKEN}" ]]; then
    echo "No github token provided. Cloning public repo."
    git clone https://$GH_REPO &
  else
    echo "found a github token. Cloning repo."
    git clone https://$GH_TOKEN@$GH_REPO &
  fi
fi

if [[ "$CODEDIR" == *".git"* ]]; then
  echo "Before " + $CODEDIR
  CODEDIR=${CODEDIR%".git"}
  echo "After " + $CODEDIR
fi

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

cp /tmp/.bashrc /home/coder/.bashrc

/usr/local/go/bin/go install golang.org/x/tools/gopls@latest &

/usr/bin/code-server --install-extension golang.go &

dumb-init /usr/bin/code-server "$@", "$CODEDIR"
