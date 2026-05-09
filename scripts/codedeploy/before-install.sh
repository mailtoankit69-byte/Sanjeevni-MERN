#!/bin/bash
set -euo pipefail

echo "=== BeforeInstall: Stopping existing application ==="

# Stop the app if running
if systemctl is-active --quiet Sanjeevi-backend; then
    systemctl stop Sanjeevi-backend
fi

# Clean old deployment
rm -rf /opt/Sanjeevi/backend/*

echo "=== BeforeInstall: Complete ==="
