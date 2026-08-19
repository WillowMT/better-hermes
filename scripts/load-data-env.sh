# Load Hermes/user env vars from the mounted data volume.
if [ -f /opt/data/.env ]; then
  set -a
  # shellcheck disable=SC1091
  . /opt/data/.env
  set +a
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
