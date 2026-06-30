#!/command/with-contenv sh
# Photon sidecar lives under the immutable /opt/hermes tree. Hermes setup
# runs `npm ci` there as the hermes user, which fails unless this sidecar
# directory is explicitly writable. Runs as root on every container boot.
set -eu

PHOTON_SIDECAR="/opt/hermes/plugins/platforms/photon/sidecar"

if [ ! -f "$PHOTON_SIDECAR/package.json" ]; then
  echo "[photon-sidecar] No package.json — skipping"
  exit 0
fi

echo "[photon-sidecar] Preparing writable sidecar directory"
chmod u+w "$PHOTON_SIDECAR" 2>/dev/null || true

if [ ! -d "$PHOTON_SIDECAR/node_modules" ]; then
  echo "[photon-sidecar] Installing Node deps..."
  (
    cd "$PHOTON_SIDECAR"
    npm ci --prefer-offline --no-audit 2>/dev/null || npm install --prefer-offline --no-audit
  )
fi

chown -R hermes:hermes "$PHOTON_SIDECAR" 2>/dev/null || true
chmod -R u+w "$PHOTON_SIDECAR" 2>/dev/null || true

echo "[photon-sidecar] Ready"
