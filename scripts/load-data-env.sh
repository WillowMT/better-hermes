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

# agent-browser — use Hermes Playwright Chromium (no separate `agent-browser install`)
if [ -z "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ] && [ -f /etc/hermes/agent-browser-executable-path ]; then
  export AGENT_BROWSER_EXECUTABLE_PATH="$(tr -d '[:space:]' < /etc/hermes/agent-browser-executable-path)"
fi
