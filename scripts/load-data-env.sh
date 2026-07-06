# Load Hermes/user env vars from the mounted data volume.
if [ -f /opt/data/.env ]; then
  set -a
  # shellcheck disable=SC1091
  . /opt/data/.env
  set +a
fi

# gh CLI reads GH_TOKEN; mirror when only GITHUB_TOKEN is set in .env
if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  export GH_TOKEN="$GITHUB_TOKEN"
fi

# agent-browser — canonical state under HERMES_HOME, not sandboxed HOME
_hermes_data="${HERMES_REAL_HOME:-${HERMES_HOME:-/opt/data}}"
_ab_dir="$_hermes_data/.agent-browser"
if [ -f /etc/hermes/agent-browser-state-dir ]; then
  _ab_dir="$(tr -d '[:space:]' < /etc/hermes/agent-browser-state-dir)"
fi
mkdir -p "$_ab_dir" 2>/dev/null || true
export AGENT_BROWSER_SOCKET_DIR="${AGENT_BROWSER_SOCKET_DIR:-$_ab_dir}"
if [ -f "$_ab_dir/config.json" ]; then
  export AGENT_BROWSER_CONFIG="${AGENT_BROWSER_CONFIG:-$_ab_dir/config.json}"
fi
# Hermes terminal home isolation sets HOME=/opt/data/home; share ~/.agent-browser
_sandbox_home="$_hermes_data/home"
if [ -n "${HOME:-}" ] && [ "$HOME" = "$_sandbox_home" ] && [ ! -e "$HOME/.agent-browser" ]; then
  ln -sf "$_ab_dir" "$HOME/.agent-browser" 2>/dev/null || true
fi
if [ -z "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ] && [ -f /etc/hermes/agent-browser-executable-path ]; then
  export AGENT_BROWSER_EXECUTABLE_PATH="$(tr -d '[:space:]' < /etc/hermes/agent-browser-executable-path)"
fi

# gcloud — persist config/credentials on the Hermes data volume, not sandbox HOME
_gcloud_config="${HERMES_REAL_HOME:-${HERMES_HOME:-/opt/data}}/.config/gcloud"
mkdir -p "$_gcloud_config" 2>/dev/null || true
export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-$_gcloud_config}"
export CLOUDSDK_CORE_DISABLE_PROMPTS="${CLOUDSDK_CORE_DISABLE_PROMPTS:-1}"
_sandbox_gcloud="$_hermes_data/home/.config/gcloud"
if [ -n "${HOME:-}" ] && [ "$HOME" = "$_sandbox_home" ]; then
  mkdir -p "$_hermes_data/home/.config" 2>/dev/null || true
  if [ ! -e "$_sandbox_gcloud" ]; then
    ln -sf "$_gcloud_config" "$_sandbox_gcloud" 2>/dev/null || true
  fi
fi
