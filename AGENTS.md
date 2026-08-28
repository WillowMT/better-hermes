## Learned User Preferences

- Bake tool CLIs and dependencies into the Docker image at build time rather than relying on runtime installs inside the container.
- Auto-load `/opt/data/.env` into shells and mirror `GH_TOKEN` from `GITHUB_TOKEN` when only the latter is set (what `gh` expects).
- Persist tool auth/config on the Hermes data volume with symlinks from the sandboxed `HOME`, not under `/opt/data/home` directly.

## Learned Workspace Facts

- `better-hermes` extends `nousresearch/hermes-agent`; default base tag is `v2026.7.20` via `HERMES_VERSION` in `.env`.
- `/opt/hermes` is read-only at runtime (`HERMES_DISABLE_LAZY_INSTALLS=1`); Python optional dependencies must be baked into the image.
- Persistent Hermes state lives on `/opt/data`; `scripts/load-data-env.sh` sources `/opt/data/.env` via `BASH_ENV`, `/etc/profile.d`, and the `hermes` user `.bashrc`.
- Hermes terminal home isolation sets `HOME=/opt/data/home` while `HERMES_HOME=/opt/data`; tool dirs like `.wrangler`, `.config/turso`, `.config/bws`, and `.bws` symlink to canonical paths under `/opt/data`.
- `docker-compose.yml` passes tokens/secrets from the host `.env` (including `BWS_ACCESS_TOKEN`); `.env.example` documents expected variables.
- Baked-in CLIs include gh, wrangler, turso, Bitwarden Secrets Manager (`bws`), PostgreSQL client (`pg_dumpall`, `pg_dump`, `psql`), zip/unzip, nano, and the Python package faster-whisper.
- Dashboard auth is required when `HERMES_DASHBOARD=1` binds non-loopback; basic auth uses `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`, `PASSWORD`, and `SECRET` env vars.
- Interactive shell tab completion needs `docker exec -it --user hermes hermes-telegram bash`; `sh`/dash has no completion and `bash-completion` is not installed.
