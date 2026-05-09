#!/bin/bash
set -euo pipefail

echo "=== ApplicationStart: Starting application ==="

# Create systemd service if not exists
cat > /etc/systemd/system/Sanjeevi-backend.service << 'EOF'
[Unit]
Description=Sanjeevi Backend API
After=network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/Sanjeevi/backend
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production

# Security hardening
NoNewPrivileges=true

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
systemctl daemon-reload
systemctl enable Sanjeevi-backend
systemctl start Sanjeevi-backend

# Wait briefly and verify the service is running
sleep 3
if systemctl is-active --quiet Sanjeevi-backend; then
    echo "=== ApplicationStart: Service is running ==="
else
    echo "=== ApplicationStart: Service FAILED to start ==="
    systemctl status Sanjeevi-backend --no-pager || true
    journalctl -u Sanjeevi-backend --no-pager -n 30 || true
    exit 1
fi

echo "=== ApplicationStart: Complete ==="
