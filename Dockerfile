# Extend the official Hermes image with tools baked in at build time.
# Runtime installs into /opt/hermes are disabled in published images.
# ARG HERMES_VERSION=v2026.6.19
ARG HERMES_VERSION=latest
FROM nousresearch/hermes-agent:${HERMES_VERSION}

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nano \
        curl \
        ca-certificates \
        gnupg \
        zip \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI — `gh` for repos, PRs, issues, and Actions
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Google Cloud CLI — `gcloud`, `gsutil`, `bq` (config persisted under /opt/data)
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg \
    && chmod go+r /etc/apt/keyrings/google-cloud.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/* \
    && gcloud --version

# Turso CLI — libSQL edge databases (`turso db`, `turso auth`, etc.)
RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) TURSO_ARCH="x86_64" ;; \
         arm64) TURSO_ARCH="aarch64" ;; \
         *) echo "Unsupported architecture for turso: $ARCH" >&2; exit 1 ;; \
       esac \
    && curl -fsSL \
         "https://github.com/tursodatabase/homebrew-tap/releases/latest/download/homebrew-tap_Linux_${TURSO_ARCH}.tar.gz" \
         -o /tmp/turso.tar.gz \
    && tar -C /usr/local/bin -zxf /tmp/turso.tar.gz turso \
    && rm /tmp/turso.tar.gz \
    && chmod +x /usr/local/bin/turso \
    && turso --version

# Deno CLI — enables `deno deploy` (token via DENO_DEPLOY_TOKEN at runtime)
ENV DENO_INSTALL=/usr/local
RUN curl -fsSL https://deno.land/install.sh | sh

# Vercel CLI — deploy and manage projects (`vercel`, `vercel deploy`, etc.)
# Wrangler CLI — Cloudflare Workers, Pages, R2, D1 (`wrangler deploy`, etc.)
RUN npm install -g vercel wrangler \
    && command -v vercel >/dev/null \
    && command -v wrangler >/dev/null

# agent-browser CLI — browser path resolved at boot (see cont-init script).
# Install from /tmp: Hermes WORKDIR (/opt/hermes) is read-only in published images.
WORKDIR /tmp
RUN npm install -g agent-browser --force \
    && AB_ROOT="$(npm root -g)/agent-browser" \
    && node "$AB_ROOT/scripts/postinstall.js" \
    && NATIVE_BIN="$(find "$AB_ROOT" -type f -executable -name 'agent-browser-*' 2>/dev/null | head -n 1)" \
    && if [ -z "$NATIVE_BIN" ]; then \
         echo "ERROR: agent-browser native binary not found after install" >&2; \
         exit 1; \
       fi \
    && command -v agent-browser >/dev/null
WORKDIR /opt/hermes

# Speech-to-text for voice memo transcription; Exa web search/extract SDK.
# Hermes Docker disables lazy installs (HERMES_DISABLE_LAZY_INSTALLS=1) and
# checks exact pins via tools.lazy_deps — must match search.exa (exa-py==2.10.2).
RUN uv pip install --python /opt/hermes/.venv/bin/python faster-whisper "exa-py==2.10.2" \
    && /opt/hermes/.venv/bin/python -c "from importlib.metadata import version; assert version('exa-py') == '2.10.2'"

# Photon sidecar — npm deps must be baked and the dir must stay writable for
# `hermes photon setup` (which always re-runs npm ci). /opt/hermes is a-w.
RUN PHOTON_SIDECAR=/opt/hermes/plugins/platforms/photon/sidecar \
    && if [ -f "${PHOTON_SIDECAR}/package.json" ]; then \
      chmod u+w "${PHOTON_SIDECAR}"; \
      cd "${PHOTON_SIDECAR}"; \
      npm ci --prefer-offline --no-audit \
        || npm install --prefer-offline --no-audit; \
      chown -R hermes:hermes "${PHOTON_SIDECAR}"; \
      chmod -R u+w "${PHOTON_SIDECAR}"; \
    fi

# Re-apply sidecar permissions on every boot (before gateway starts)
COPY scripts/cont-init-photon-sidecar.sh /etc/cont-init.d/025-photon-sidecar-deps
RUN chmod 0755 /etc/cont-init.d/025-photon-sidecar-deps

# Point agent-browser at Hermes Playwright Chromium on boot
COPY scripts/cont-init-agent-browser.sh /etc/cont-init.d/026-agent-browser
RUN chmod 0755 /etc/cont-init.d/026-agent-browser

# Auto-load /opt/data/.env in shells (gh, gcloud, turso, vercel, wrangler, deno, etc.)
COPY scripts/load-data-env.sh /etc/hermes/load-data-env.sh
RUN chmod 644 /etc/hermes/load-data-env.sh \
    && ln -sf /etc/hermes/load-data-env.sh /etc/profile.d/hermes-data-env.sh \
    && HERMES_HOME_DIR="$(getent passwd hermes | cut -d: -f6)" \
    && printf '\n# Load Hermes/user env vars\n. /etc/hermes/load-data-env.sh\n' >> "${HERMES_HOME_DIR}/.bashrc"

# Non-interactive bash (Hermes tool subprocesses) also sources this
ENV BASH_ENV=/etc/hermes/load-data-env.sh

USER hermes
