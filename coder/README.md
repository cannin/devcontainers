---
display_name: Codex Docker Containers from Repo Dev Container Dockerfile
description: Provision Docker containers as Coder workspaces
icon: ../../../site/static/icon/docker.png
maintainer_github: coder
verified: true
tags: [docker, container]
---

# Remote Development on Docker Containers

Provision Docker containers as [Coder workspaces](https://coder.com/docs/workspaces) with this template.

## Coder Setup
### Install Caddy (For Custom Url)
See: https://caddyserver.com/docs/install#debian-ubuntu-raspbian

```bash
  sudo systemctl reload caddy
```

### Install Coder

```bash
  curl -L https://coder.com/install.sh | sh
```

### Run Coder
#### Notes
* Device Flow login breaks read organization permissions (never read)
* OAuth read:org permission can be granted by owner during first login

```bash
export CODER_ACCESS_URL=https://coder.FIXME.com

export CODER_OAUTH2_GITHUB_CLIENT_ID=FIXME
export CODER_OAUTH2_GITHUB_CLIENT_SECRET=FIXME

export CODER_OAUTH2_GITHUB_ALLOW_SIGNUPS=true
export CODER_OAUTH2_GITHUB_ALLOWED_ORGS="FIXME"
export CODER_OAUTH2_GITHUB_ALLOW_EVERYONE=false
export CODER_OAUTH2_GITHUB_DEVICE_FLOW=false
export CODER_OAUTH2_GITHUB_DEFAULT_PROVIDER_ENABLE=false

coder server --address 127.0.0.1:3000
```

### Uninstall Coder
```bash
sudo rm -f /usr/bin/coder
sudo rm -f /etc/coder.d/coder.env
rm -rf ~/.config/coderv2
rm -rf ~/.cache/coder
```

### Test Github Organization Membership

```bash
curl \
  -H "Authorization: Bearer FIXME" \
  -H "Accept: application/vnd.github+json" \
  'https://api.github.com/user/memberships/orgs?per_page=100&state=active'
```

## Coder Quickstart (NOT TESTED)

```bash
export CODER_DATA=$HOME/.config/coderv2-docker
export DOCKER_GROUP=$(getent group docker | cut -d: -f3)
docker run --rm -it --name coder -v $CODER_DATA:/home/coder/.config -v /var/run/docker.sock:/var/run/docker.sock --group-add $DOCKER_GROUP ghcr.io/coder/coder:latest
```

## Architecture

This template provisions the following resources:

- Docker image (built by Docker socket and kept locally)
- Docker container pod (ephemeral)
- A clone of a git repo (given a repo URL)
- OpenAI Codex (given a Azure OpenAI API key)

This means, when the workspace restarts, any tools or files outside of the home directory are not persisted. To pre-bake tools into the workspace (e.g. `python3`), modify the container image.

### Editing the image

Edit the repo `.devcontainer/Dockerfile`
