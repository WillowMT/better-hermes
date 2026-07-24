# Remove gcloud and Vercel CLI Installation

## Scope

Stop baking the Google Cloud CLI and Vercel CLI into the `better-hermes` Docker image. Remove runtime setup and documentation that specifically claims gcloud is installed or persists its configuration. Retain `VERCEL_TOKEN` in the Compose and example environment configuration so downstream workloads can continue consuming it.

## Changes

- Delete the Google Cloud apt repository, key, package installation, and version check from `Dockerfile`.
- Remove `vercel` from the global npm installation and delete its executable check while preserving the Wrangler installation.
- Remove gcloud configuration directory creation, `CLOUDSDK_CONFIG`, and sandbox-home symlink handling from `scripts/load-data-env.sh`.
- Update comments and `AGENTS.md` workspace facts so they no longer list gcloud or Vercel as baked-in tools.
- Remove the obsolete gcloud persistence comment from `.env.example`; do not remove unrelated Google Cloud environment variables if present.
- Keep `VERCEL_TOKEN` passthrough and documentation unchanged.

## Verification

- Search tracked project files to confirm there are no remaining installation commands or baked-in-tool claims for gcloud or Vercel.
- Validate the Docker Compose configuration and shell syntax for `scripts/load-data-env.sh`.
- Inspect the resulting diff for accidental changes outside the approved scope.

