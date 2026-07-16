## Learned User Preferences

- Bake tool CLIs and dependencies into the Docker image at build time rather than relying on runtime installs inside the container.
- Install Deno via `curl -fsSL https://deno.land/install.sh | sh` without a version pin so builds pull the latest stable release.
- Auto-load `/opt/data/.env` into shells and mirror `GH_TOKEN` from `GITHUB_TOKEN` when only the latter is set (what `gh` expects).
- Persist tool auth/config on the Hermes data volume with symlinks from the sandboxed `HOME`, not under `/opt/data/home` directly.

## Learned Workspace Facts

- `better-hermes` extends `nousresearch/hermes-agent`; default base tag is `v2026.7.7.2` via `HERMES_VERSION` in `.env`.
- `/opt/hermes` is read-only at runtime (`HERMES_DISABLE_LAZY_INSTALLS=1`); Python optional deps must match Hermes exact pins in `tools.lazy_deps` (e.g. `exa-py==2.10.2`).
- Persistent Hermes state lives on `/opt/data`; `scripts/load-data-env.sh` sources `/opt/data/.env` via `BASH_ENV`, `/etc/profile.d`, and the `hermes` user `.bashrc`.
- Hermes terminal home isolation sets `HOME=/opt/data/home` while `HERMES_HOME=/opt/data`; tool dirs like `.agent-browser`, `.config/gcloud`, `.wrangler`, and `.config/turso` symlink to canonical paths under `/opt/data`.
- `docker-compose.yml` passes tokens/secrets from the host `.env` (including `CURSOR_API_KEY` for Cursor Agent CLI); `.env.example` documents expected variables.
- Baked-in CLIs include gh, gcloud, deno, vercel, wrangler, turso, agent-browser, Cursor Agent (`agent`), zip/unzip, nano, and Python packages faster-whisper and exa-py.
- agent-browser installs from `/tmp` (base WORKDIR is read-only); Playwright Chromium path and state dir are set at boot via `cont-init-agent-browser.sh`.
- Photon sidecar deps at `/opt/hermes/plugins/platforms/photon/sidecar` need build-time `npm ci` plus `cont-init-photon-sidecar.sh` on boot so `hermes photon setup` can write `node_modules`.
- Dashboard auth is required when `HERMES_DASHBOARD=1` binds non-loopback; basic auth uses `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`, `PASSWORD`, and `SECRET` env vars.
- Interactive shell tab completion needs `docker exec -it --user hermes hermes-telegram bash`; `sh`/dash has no completion and `bash-completion` is not installed.
