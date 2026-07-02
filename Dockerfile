# Extend the official Hermes image with tools baked in at build time.
# Runtime installs into /opt/hermes are disabled in published images.
ARG HERMES_VERSION=v2026.6.19
FROM nousresearch/hermes-agent:${HERMES_VERSION}

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nano \
        curl \
        ca-certificates \
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

# Deno CLI — enables `deno deploy` (token via DENO_DEPLOY_TOKEN at runtime)
ENV DENO_INSTALL=/usr/local
RUN curl -fsSL https://deno.land/install.sh | sh

# Vercel CLI — deploy and manage projects (`vercel`, `vercel deploy`, etc.)
RUN npm install -g vercel

# agent-browser CLI — reuses Playwright Chromium already baked in the Hermes base image
RUN npm install -g agent-browser \
    && AGENT_BROWSER_BIN="$(find /opt/hermes/.playwright -type f -executable \
         \( -name 'chrome' -o -name 'chromium' -o -name 'chrome-headless-shell' \
            -o -name 'headless_shell' -o -name 'chromium-browser' \) \
         2>/dev/null | head -n 1)" \
    && if [ -z "$AGENT_BROWSER_BIN" ]; then \
         echo "ERROR: Playwright Chromium not found under /opt/hermes/.playwright" >&2; \
         exit 1; \
       fi \
    && printf '%s\n' "$AGENT_BROWSER_BIN" > /etc/hermes/agent-browser-executable-path \
    && chmod 644 /etc/hermes/agent-browser-executable-path \
    && printf 'export AGENT_BROWSER_EXECUTABLE_PATH=%s\n' "$AGENT_BROWSER_BIN" \
         > /etc/profile.d/agent-browser-hermes.sh \
    && chmod 644 /etc/profile.d/agent-browser-hermes.sh \
    && command -v agent-browser >/dev/null

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

# Auto-load /opt/data/.env in shells (gh, vercel, deno, etc.)
COPY scripts/load-data-env.sh /etc/hermes/load-data-env.sh
RUN chmod 644 /etc/hermes/load-data-env.sh \
    && ln -sf /etc/hermes/load-data-env.sh /etc/profile.d/hermes-data-env.sh \
    && HERMES_HOME_DIR="$(getent passwd hermes | cut -d: -f6)" \
    && printf '\n# Load Hermes/user env vars\n. /etc/hermes/load-data-env.sh\n' >> "${HERMES_HOME_DIR}/.bashrc"

# Non-interactive bash (Hermes tool subprocesses) also sources this
ENV BASH_ENV=/etc/hermes/load-data-env.sh

USER hermes
