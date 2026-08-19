# Extend the official Hermes image with tools baked in at build time.
# Runtime installs into /opt/hermes are disabled in published images.
# Override via docker-compose build arg / .env HERMES_VERSION (default: v2026.7.20).
ARG HERMES_VERSION=v2026.7.20
FROM nousresearch/hermes-agent:${HERMES_VERSION}

# Fail fast if the base image is missing Telegram deps (common cause of silent gateway failures).
RUN /opt/hermes/.venv/bin/python -c "import telegram; print('python-telegram-bot', telegram.__version__)"

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nano \
        curl \
        ca-certificates \
        gnupg \
        zip \
        unzip \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && pg_dumpall --version


# Bitwarden Secrets Manager CLI — `bws` (auth via BWS_ACCESS_TOKEN at runtime)
# Official installer may land in ~/.local/bin when sudo is unavailable; normalize to PATH.
RUN curl -fsSL https://bws.bitwarden.com/install | sh \
    && if [ ! -x /usr/local/bin/bws ] && [ -x "${HOME}/.local/bin/bws" ]; then \
         install -m 755 "${HOME}/.local/bin/bws" /usr/local/bin/bws; \
       fi \
    && command -v bws >/dev/null \
    && bws --version

# Notion CLI — manage Notion from the terminal (`ntn`)
RUN curl -fsSL https://ntn.dev | bash \
    && command -v ntn >/dev/null \
    && ntn --version

# Auto-load /opt/data/.env in shells (gh, turso, wrangler, bws, etc.)
COPY scripts/load-data-env.sh /etc/hermes/load-data-env.sh
RUN chmod 644 /etc/hermes/load-data-env.sh \
    && ln -sf /etc/hermes/load-data-env.sh /etc/profile.d/hermes-data-env.sh \
    && HERMES_HOME_DIR="$(getent passwd hermes | cut -d: -f6)" \
    && printf '\n# Load Hermes/user env vars\n. /etc/hermes/load-data-env.sh\n' >> "${HERMES_HOME_DIR}/.bashrc"

# Non-interactive bash (Hermes tool subprocesses) also sources this
ENV BASH_ENV=/etc/hermes/load-data-env.sh

USER hermes
