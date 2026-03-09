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

## Architecture

This template provisions the following resources:

- Docker image (built by Docker socket and kept locally)
- Docker container pod (ephemeral)
- A clone of a git repo (given a repo URL)
- OpenAI Codex (given a Azure OpenAI API key)

This means, when the workspace restarts, any tools or files outside of the home directory are not persisted. To pre-bake tools into the workspace (e.g. `python3`), modify the container image. 

### Editing the image

Edit the repo `.devcontainer/Dockerfile` 
