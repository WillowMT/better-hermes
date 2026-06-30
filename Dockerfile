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

# Speech-to-text for voice memo transcription
RUN uv pip install --python /opt/hermes/.venv/bin/python faster-whisper

USER hermes
