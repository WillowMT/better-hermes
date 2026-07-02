#!/bin/sh
# Resolve Playwright Chromium for agent-browser (shell + tool subprocesses).
# Mirrors Hermes stage2-hook browser discovery; base image sets this for s6
# services via /run/s6/container_environment, but docker exec shells need it too.
set -eu

if [ -n "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ]; then
  exit 0
fi

PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/hermes/.playwright}"
mkdir -p /etc/hermes

if [ ! -d "$PLAYWRIGHT_BROWSERS_PATH" ]; then
  echo "[cont-init] agent-browser: $PLAYWRIGHT_BROWSERS_PATH missing; skipping" >&2
  exit 0
fi

browser_bin=$(find "$PLAYWRIGHT_BROWSERS_PATH" -type f -executable \
  \( -name 'chrome' -o -name 'chromium' \
     -o -name 'chrome-headless-shell' -o -name 'headless_shell' \
     -o -name 'chromium-browser' \) \
  2>/dev/null | head -n 1)

if [ -z "$browser_bin" ]; then
  echo "[cont-init] agent-browser: no Chromium binary under $PLAYWRIGHT_BROWSERS_PATH" >&2
  exit 0
fi

printf '%s' "$browser_bin" > /etc/hermes/agent-browser-executable-path
chmod 644 /etc/hermes/agent-browser-executable-path
printf 'export AGENT_BROWSER_EXECUTABLE_PATH=%s\n' "$browser_bin" \
  > /etc/profile.d/agent-browser-hermes.sh
chmod 644 /etc/profile.d/agent-browser-hermes.sh
echo "[cont-init] agent-browser: AGENT_BROWSER_EXECUTABLE_PATH=$browser_bin"
