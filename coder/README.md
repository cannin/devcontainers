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

## Coder Quickstart

```
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
