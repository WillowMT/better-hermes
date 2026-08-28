#!/command/with-contenv sh
# Seed the writable data-volume bridge from the dependency-complete image copy.
set -eu

IMAGE_BRIDGE="/opt/hermes/scripts/whatsapp-bridge"
DATA_BRIDGE="/opt/data/scripts/whatsapp-bridge"

if [ ! -f "$IMAGE_BRIDGE/package.json" ]; then
  echo "[whatsapp-bridge] Image bridge is unavailable; skipping"
  exit 0
fi

mkdir -p "$DATA_BRIDGE"

# Keep bridge source synchronized with the selected Hermes image.
for file in "$IMAGE_BRIDGE"/*.js "$IMAGE_BRIDGE"/package*.json; do
  [ -e "$file" ] && cp -a "$file" "$DATA_BRIDGE/"
done

# Refresh dependencies only when the baked package hash changes.
if ! cmp -s \
  "$IMAGE_BRIDGE/node_modules/.hermes-pkg-hash" \
  "$DATA_BRIDGE/node_modules/.hermes-pkg-hash"; then
  rm -rf "$DATA_BRIDGE/node_modules"
  cp -a "$IMAGE_BRIDGE/node_modules" "$DATA_BRIDGE/node_modules"
fi

chown -R hermes:hermes "$DATA_BRIDGE"

echo "[whatsapp-bridge] Baked dependencies are ready"
