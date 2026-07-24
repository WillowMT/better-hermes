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

# wrangler — OAuth/config under ~/.wrangler; persist on the Hermes data volume
_wrangler_dir="$_hermes_data/.wrangler"
mkdir -p "$_wrangler_dir" 2>/dev/null || true
if [ -n "${HOME:-}" ] && [ "$HOME" = "$_sandbox_home" ] && [ ! -e "$HOME/.wrangler" ]; then
  ln -sf "$_wrangler_dir" "$HOME/.wrangler" 2>/dev/null || true
fi

# turso — CLI auth/settings under ~/.config/turso; persist on the Hermes data volume
_turso_config="$_hermes_data/.config/turso"
mkdir -p "$_turso_config" 2>/dev/null || true
export TURSO_CONFIG_FOLDER="${TURSO_CONFIG_FOLDER:-$_turso_config}"
_sandbox_turso="$_hermes_data/home/.config/turso"
if [ -n "${HOME:-}" ] && [ "$HOME" = "$_sandbox_home" ]; then
  mkdir -p "$_hermes_data/home/.config" 2>/dev/null || true
  if [ ! -e "$_sandbox_turso" ]; then
    ln -sf "$_turso_config" "$_sandbox_turso" 2>/dev/null || true
  fi
fi

# bws — Bitwarden Secrets Manager state/config on the Hermes data volume
_bws_config="$_hermes_data/.config/bws"
_bws_dot="$_hermes_data/.bws"
mkdir -p "$_bws_config" "$_bws_dot" 2>/dev/null || true
_sandbox_bws_config="$_hermes_data/home/.config/bws"
_sandbox_bws_dot="$_hermes_data/home/.bws"
if [ -n "${HOME:-}" ] && [ "$HOME" = "$_sandbox_home" ]; then
  mkdir -p "$_hermes_data/home/.config" 2>/dev/null || true
  if [ ! -e "$_sandbox_bws_config" ]; then
    ln -sf "$_bws_config" "$_sandbox_bws_config" 2>/dev/null || true
  fi
  if [ ! -e "$_sandbox_bws_dot" ]; then
    ln -sf "$_bws_dot" "$_sandbox_bws_dot" 2>/dev/null || true
  fi
fi
