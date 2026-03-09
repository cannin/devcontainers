terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

###############################################################################
# VARIABLES
###############################################################################

variable "docker_socket" {
  description = "Optional docker daemon URI"
  type        = string
  default     = ""
}

###############################################################################
# PROVIDER
###############################################################################

provider "docker" {
  host = var.docker_socket != "" ? var.docker_socket : null
}

###############################################################################
# CODER DATA
###############################################################################

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

###############################################################################
# PARAMETERS
###############################################################################

data "coder_parameter" "repo_url" {
  type         = "string"
  name         = "repo_url"
  display_name = "Git Repository"
  description  = "Repository cloned into workspace"
  default      = "https://github.com/cannin/devcontainers"
  mutable      = true
}

data "coder_parameter" "codex_config_url" {
  type         = "string"
  name         = "codex_config_url"
  display_name = "Codex config.toml URL"
  description  = "URL for config.toml placed in /root/.codex"
  mutable      = true
}

data "coder_parameter" "codex_agents_url" {
  type         = "string"
  name         = "codex_agents_url"
  display_name = "Codex AGENTS.md URL"
  description  = "URL for AGENTS.md placed in /root/.codex"
  mutable      = true
}

data "coder_parameter" "codex_key" {
  type         = "string"
  name         = "codex"
  display_name = "Codex AZURE_OPENAI_API_KEY"
  description  = "Environment variable AZURE_OPENAI_API_KEY"
  mutable      = true
}

###############################################################################
# LOCALS
###############################################################################

locals {
  repo_name = replace(basename(data.coder_parameter.repo_url.value), ".git", "")
  build_repo_path = "${path.module}/repo"
  runtime_repo_path = "/root/workspace/${local.repo_name}"
}

###############################################################################
# CLONE REPO FOR BUILD
###############################################################################

resource "null_resource" "clone_repo_for_build" {

  provisioner "local-exec" {
    command = <<EOT
rm -rf ${local.build_repo_path}
git clone ${data.coder_parameter.repo_url.value} ${local.build_repo_path}
EOT
  }
}

###############################################################################
# BUILD IMAGE FROM .devcontainer/Dockerfile
###############################################################################

resource "docker_image" "workspace_image" {

  name = "coder-workspace:latest"

  build {
    context    = local.build_repo_path
    dockerfile = ".devcontainer/Dockerfile"
  }

  depends_on = [null_resource.clone_repo_for_build]
}

###############################################################################
# CODER AGENT
###############################################################################

resource "coder_agent" "main" {

  arch = data.coder_provisioner.me.arch
  os   = "linux"

  startup_script = <<EOT
set -e

mkdir -p /root/workspace
mkdir -p /root/.codex

if [ ! -d "${local.runtime_repo_path}" ]; then
  git clone ${data.coder_parameter.repo_url.value} ${local.runtime_repo_path}
fi

ln -s ${local.runtime_repo_path} /workspace 2>/dev/null || true

curl -L ${data.coder_parameter.codex_config_url.value} \
  -o /root/.codex/config.toml

curl -L ${data.coder_parameter.codex_agents_url.value} \
  -o /root/.codex/AGENTS.md
EOT

  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
  }
}

###############################################################################
# CODE SERVER
###############################################################################

module "code-server" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/code-server/coder"
  version = "~> 1.0"

  agent_id = coder_agent.main.id
}

###############################################################################
# ROOT HOME VOLUME
###############################################################################

resource "docker_volume" "root_home" {
  name = "coder-${data.coder_workspace.me.id}-root"

  lifecycle {
    ignore_changes = all
  }
}

###############################################################################
# WORKSPACE CONTAINER
###############################################################################

resource "docker_container" "workspace" {

  count = data.coder_workspace.me.start_count

  image = docker_image.workspace_image.image_id

  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = data.coder_workspace.me.name

  entrypoint = [
    "sh",
    "-c",
    replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
  ]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "AZURE_OPENAI_API_KEY=${data.coder_parameter.codex_key.value}"
  ]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    container_path = "/root"
    volume_name    = docker_volume.root_home.name
  }

  working_dir = "/workspace"

  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
}
