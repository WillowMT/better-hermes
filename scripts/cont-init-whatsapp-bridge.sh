#!/command/with-contenv sh
# The gateway installs the WhatsApp bridge into the persistent data volume as
# the hermes user. Prepare the directory before the non-root gateway starts.
set -eu

WHATSAPP_BRIDGE="/opt/data/scripts/whatsapp-bridge"

mkdir -p "$WHATSAPP_BRIDGE"
chown -R hermes:hermes "$WHATSAPP_BRIDGE"

echo "[whatsapp-bridge] Persistent bridge directory is writable"
