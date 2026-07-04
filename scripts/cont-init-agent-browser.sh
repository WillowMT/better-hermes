#!/bin/sh
# agent-browser: Playwright Chromium path + unified state under HERMES_HOME.
# Hermes tool shells use HOME=/opt/data/home (terminal home isolation); agent-browser
# reads ~/.agent-browser. We keep canonical state at /opt/data/.agent-browser and
# symlink the sandbox home so auth/config is shared.
set -eu

HERMES_DATA="${HERMES_REAL_HOME:-${HERMES_HOME:-/opt/data}}"
AB_DIR="$HERMES_DATA/.agent-browser"
SANDBOX_HOME="$HERMES_DATA/home"

mkdir -p "$AB_DIR" "$SANDBOX_HOME" /etc/hermes
chown -R hermes:hermes "$AB_DIR" "$SANDBOX_HOME" 2>/dev/null || true

if [ ! -e "$SANDBOX_HOME/.agent-browser" ]; then
  ln -sf "$AB_DIR" "$SANDBOX_HOME/.agent-browser"
elif [ -d "$SANDBOX_HOME/.agent-browser" ] && [ ! -L "$SANDBOX_HOME/.agent-browser" ]; then
  echo "[cont-init] agent-browser: $SANDBOX_HOME/.agent-browser is a real dir; not replacing" >&2
fi

printf '%s' "$AB_DIR" > /etc/hermes/agent-browser-state-dir
chmod 644 /etc/hermes/agent-browser-state-dir

if [ -z "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ] && [ ! -f /etc/hermes/agent-browser-executable-path ]; then
  PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/hermes/.playwright}"
  if [ -d "$PLAYWRIGHT_BROWSERS_PATH" ]; then
    browser_bin=$(find "$PLAYWRIGHT_BROWSERS_PATH" -type f -executable \
      \( -name 'chrome' -o -name 'chromium' \
         -o -name 'chrome-headless-shell' -o -name 'headless_shell' \
         -o -name 'chromium-browser' \) \
      2>/dev/null | head -n 1)
    if [ -n "$browser_bin" ]; then
      printf '%s' "$browser_bin" > /etc/hermes/agent-browser-executable-path
      chmod 644 /etc/hermes/agent-browser-executable-path
      echo "[cont-init] agent-browser: AGENT_BROWSER_EXECUTABLE_PATH=$browser_bin"
    else
      echo "[cont-init] agent-browser: no Chromium binary under $PLAYWRIGHT_BROWSERS_PATH" >&2
    fi
  else
    echo "[cont-init] agent-browser: $PLAYWRIGHT_BROWSERS_PATH missing; skipping Chromium path" >&2
  fi
fi

{
  printf 'export AGENT_BROWSER_SOCKET_DIR=%s\n' "$AB_DIR"
  if [ -f "$AB_DIR/config.json" ]; then
    printf 'export AGENT_BROWSER_CONFIG=%s\n' "$AB_DIR/config.json"
  fi
  if [ -f /etc/hermes/agent-browser-executable-path ]; then
    printf 'export AGENT_BROWSER_EXECUTABLE_PATH=%s\n' \
      "$(tr -d '[:space:]' < /etc/hermes/agent-browser-executable-path)"
  fi
} > /etc/profile.d/agent-browser-hermes.sh
chmod 644 /etc/profile.d/agent-browser-hermes.sh

echo "[cont-init] agent-browser: state dir $AB_DIR (sandbox HOME $SANDBOX_HOME)"
