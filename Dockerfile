# Extend the official Hermes image with tools baked in at build time.
# Runtime installs into /opt/hermes are disabled in published images.
# Override via docker-compose build arg / .env HERMES_VERSION (default: v2026.7.20).

ARG HERMES_VERSION=v2026.7.20
FROM nousresearch/hermes-agent:${HERMES_VERSION}

USER root

# Install system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nano \
        curl \
        ca-certificates \
        gnupg \
        pass \
        zip \
        unzip \
        postgresql-client && \
    rm -rf /var/lib/apt/lists/* && \
    pg_dumpall --version

# Fix Python SyntaxWarning in Hermes
RUN sed -i 's/venv\\Scripts/venv\\\\Scripts/' \
    /opt/hermes/hermes_cli/update_cmd.py

# Bitwarden Secrets Manager CLI
RUN curl -fsSL https://bws.bitwarden.com/install | sh && \
    if [ ! -x /usr/local/bin/bws ] && [ -x "${HOME}/.local/bin/bws" ]; then \
        install -m 755 "${HOME}/.local/bin/bws" /usr/local/bin/bws; \
    fi && \
    command -v bws >/dev/null && \
    bws --version

# Notion CLI
RUN curl -fsSL https://ntn.dev | bash && \
    command -v ntn >/dev/null && \
    ntn --version

# Himalaya
RUN curl -fsSL https://raw.githubusercontent.com/pimalaya/himalaya/master/install.sh | sh && \
    command -v himalaya >/dev/null && \
    himalaya --version

# Drop privileges for runtime
USER hermes