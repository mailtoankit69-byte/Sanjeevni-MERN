#!/bin/bash
set -euo pipefail

echo "=== AfterInstall: Installing dependencies ==="

cd /opt/Sanjeevi/backend

# Install production dependencies only
npm ci --omit=dev

# Fetch secrets from Secrets Manager and write .env
ENVIRONMENT=${ENVIRONMENT:-production}

# IMDSv2: get token first, then use it for metadata calls
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
    http://169.254.169.254/latest/meta-data/placement/region)

# Get DocumentDB credentials
DB_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "${ENVIRONMENT}/Sanjeevi/documentdb" \
    --region "$REGION" \
    --query SecretString \
    --output text)

DB_HOST=$(echo "$DB_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['host'])")
DB_PORT=$(echo "$DB_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['port'])")
DB_USER=$(echo "$DB_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
DB_PASS=$(echo "$DB_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

# Get app secrets
APP_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "${ENVIRONMENT}/Sanjeevi/app" \
    --region "$REGION" \
    --query SecretString \
    --output text)

JWT_SECRET=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['JWT_SECRET'])")
ADMIN_EMAIL=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['ADMIN_EMAIL'])")
ADMIN_PASSWORD=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['ADMIN_PASSWORD'])")
CLOUDINARY_NAME=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['CLOUDINARY_NAME'])")
CLOUDINARY_API_KEY=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['CLOUDINARY_API_KEY'])")
CLOUDINARY_SECRET_KEY=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['CLOUDINARY_SECRET_KEY'])")
RAZORPAY_KEY_ID=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['RAZORPAY_KEY_ID'])")
RAZORPAY_KEY_SECRET=$(echo "$APP_SECRET" | python3 -c "import sys,json; print(json.load(sys.stdin)['RAZORPAY_KEY_SECRET'])")

# Download DocumentDB CA bundle
if [ ! -f /opt/Sanjeevi/global-bundle.pem ]; then
    wget -q -O /opt/Sanjeevi/global-bundle.pem \
        https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
fi

# DocumentDB connection string
# MONGODB_URI="mongodb://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/Sanjeevi?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
# MONGODB_URI="mongodb://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/Sanjeevi?ssl=true&tlsCAFile=/opt/Sanjeevi/backend/rds-combined-ca-bundle.pem&retryWrites=false&authMechanism=SCRAM-SHA-1
MONGODB_URI="mongodb://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/Sanjeevi?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false&authSource=admin&tlsCAFile=/opt/Sanjeevi/global-bundle.pem"


# Write environment file
cat > /opt/Sanjeevi/backend/.env << ENVEOF
PORT=4000
MONGODB_URI=${MONGODB_URI}
TLS_CA_FILE=/opt/Sanjeevi/global-bundle.pem
JWT_SECRET=${JWT_SECRET}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
CLOUDINARY_NAME=${CLOUDINARY_NAME}
CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY}
CLOUDINARY_SECRET_KEY=${CLOUDINARY_SECRET_KEY}
RAZORPAY_KEY_ID=${RAZORPAY_KEY_ID}
RAZORPAY_KEY_SECRET=${RAZORPAY_KEY_SECRET}
ENVEOF

chmod 600 /opt/Sanjeevi/backend/.env

echo "=== AfterInstall: Complete ==="
