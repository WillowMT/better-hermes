# Lightweight Hermes Image

## Goal

Provide a `lightweight-hermes` branch that retains the Telegram gateway, Bitwarden Secrets Manager CLI (`bws`), and Notion CLI (`ntn`) while removing optional tooling and its configuration.

## Image Contents

The image retains the Telegram dependency check and these APT packages: `nano`, `curl`, `ca-certificates`, `zip`, `unzip`, and `postgresql-client`. It retains the BWS and NTN installers and the `/opt/data/.env` shell loader with persistent BWS state.

The image removes GitHub CLI, Turso, Wrangler, agent-browser, `faster-whisper`, `exa-py`, and Photon sidecar setup. It also removes the agent-browser and Photon boot hooks and their persistence setup.

## Configuration

Compose and `.env.example` retain the dashboard, Telegram, OpenRouter, Bitwarden, and Vercel settings. They remove GitHub, Exa, Cloudflare, and Turso variables because the associated tooling is not included in this branch.

## Validation

Run `git diff --check` and `docker compose config --quiet`. The Dockerfile is intentionally not built during this change because it requires pulling the full Hermes base image and external installers.
