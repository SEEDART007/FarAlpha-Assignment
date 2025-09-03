#!/usr/bin/env bash
set -euo pipefail

# Usage: remote_deploy.sh <deploy_dir>
DEPLOY_DIR="${1:-/opt/siddhartha-sayhello}"
SERVICE_NAME="siddhartha-sayhello.service"
NODE_VERSION="18"  # LTS; change if you prefer

echo "Starting remote deploy to ${DEPLOY_DIR}"

# create deploy directory
sudo mkdir -p "${DEPLOY_DIR}"
sudo chown "$USER":"$USER" "${DEPLOY_DIR}"

# remove old files and extract new files that will be uploaded into DEPLOY_DIR
# (the GitHub action will upload the project tarball into DEPLOY_DIR/upload.tar.gz)
if [ -f "${DEPLOY_DIR}/upload.tar.gz" ]; then
  tar -xzf "${DEPLOY_DIR}/upload.tar.gz" -C "${DEPLOY_DIR}"
  # uploaded files may be inside a top-level directory; move them up
  # if so, try to detect and move src, package.json into DEPLOY_DIR root
  # (we assume archive contains files at its root)
else
  echo "ERROR: ${DEPLOY_DIR}/upload.tar.gz not found. Make sure the CI uploaded it."
  exit 2
fi

cd "${DEPLOY_DIR}"

# Install Node.js if not installed (non-interactive)
if ! command -v node >/dev/null 2>&1; then
  echo "Node not found. Installing Node.js ${NODE_VERSION}..."
  # Debian/Ubuntu instructions (works on most cloud VMs)
  curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
  sudo apt-get install -y nodejs build-essential
fi

# Install app dependencies
echo "Installing npm dependencies..."
npm ci --only=production || npm install --production

# Create systemd service file
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
echo "Creating systemd service at ${SERVICE_FILE}..."
sudo tee "${SERVICE_FILE}" > /dev/null <<EOF
[Unit]
Description=Siddhartha SayHello Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${DEPLOY_DIR}
ExecStart=/usr/bin/node ${DEPLOY_DIR}/src/server.js
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and restart service
echo "Reloading systemd and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable --now "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}" || sudo journalctl -u "${SERVICE_NAME}" --no-pager -n 200

echo "Deployment finished. Service status:"
sudo systemctl status "${SERVICE_NAME}" --no-pager -l -n 20
