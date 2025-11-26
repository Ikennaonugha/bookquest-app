#!/bin/bash

# Book Finder Application - Secure Deployment Script
# Deploys using a non-root user with sudo privileges

set -euo pipefail  # Fail fast on errors

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
DEPLOY_USER="deploy"                    # Non-root user on servers
APP_PATH="/var/www/bookquest-app"
SSH_KEY_PATH="${HOME}/.ssh/web_key"  # Your private key
SSH_OPTIONS="-o StrictHostKeyChecking=yes -o UserKnownHostsFile=/dev/null -i ${SSH_KEY_PATH}"

# Load environment variables
if [ -f .env ]; then
    set -a  # automatically export variables
    source .env
    set +a
else
    echo -e "${RED}Error: .env file not found. Please create it from .env.example${NC}"
    exit 1
fi

# Required variables check
required_vars=("WEB01_IP" "WEB02_IP" "GOOGLE_BOOKS_API_KEY" "LB01_IP")
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo -e "${RED}Error: $var is not set in .env file${NC}"
        exit 1
    fi
done

# Test SSH key exists and has correct permissions
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}Error: SSH private key not found at $SSH_KEY_PATH${NC}"
    echo "Place your deploy key there or update SSH_KEY_PATH in the script."
    exit 1
fi

if [ "$(stat -c %a "$SSH_KEY_PATH")" != "600" ] && [ "$(stat -c %a "$SSH_KEY_PATH")" != "400" ]; then
    echo -e "${YELLOW}Warning: Fixing permissions on SSH key...${NC}"
    chmod 600 "$SSH_KEY_PATH"
fi

# Function to deploy to a server
deploy_to_server() {
    local SERVER_IP=$1
    local SERVER_NAME=$2

    echo -e "${YELLOW}Deploying to ${SERVER_NAME} (${SERVER_IP})...${NC}"

    # Test SSH connection first
    if ! ssh $SSH_OPTIONS $DEPLOY_USER@${SERVER_IP} "echo 'SSH connection OK'" >/dev/null 2>&1; then
        echo -e "${RED}Failed: Cannot connect to ${SERVER_IP} as ${DEPLOY_USER}${NC}"
        echo "Check your SSH key, authorized_keys on server, and network."
        return 1
    fi

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT  # Auto-cleanup

    # Prepare files
    cp index.html app.js "$TEMP_DIR/"

    # Generate config.js securely (quoted properly)
    cat > "$TEMP_DIR/config.js" << EOF
const CONFIG = {
    API_KEY: '${GOOGLE_BOOKS_API_KEY}',
    API_BASE_URL: 'https://www.googleapis.com/books/v1/volumes',
    MAX_RESULTS: 40,
    DEFAULT_SORT: 'relevance',
};
EOF

    # Sync files using rsync (much better than scp for deployments)
    rsync -avz --delete -e "ssh $SSH_OPTIONS" "$TEMP_DIR/" $DEPLOY_USER@${SERVER_IP}:${APP_PATH}/

    # Set permissions via sudo (requires deploy user to have passwordless sudo for www-data)
    ssh $SSH_OPTIONS $DEPLOY_USER@${SERVER_IP} << EOF
sudo chown -R www-data:www-data ${APP_PATH}
sudo find ${APP_PATH} -type d -exec sudo chmod 755 {} \;
sudo find ${APP_PATH} -type f -exec sudo chmod 644 {} \;
sudo chmod 755 ${APP_PATH}/app.js 2>/dev/null || true
echo "Permissions updated on ${SERVER_NAME}"
EOF

    echo -e "${GREEN}✓ Deployment to ${SERVER_NAME} (${SERVER_IP}) completed${NC}"
}

# Main deployment
echo -e "${GREEN}Starting Secure Deployment of Book Finder App${NC}"
echo "===================================================="

deploy_to_server "$WEB01_IP" "Web01"
echo
deploy_to_server "$WEB02_IP" "Web02"

echo
echo -e "${GREEN}===================================================="
echo "    All servers deployed successfully!     "
echo "===================================================${NC}"
echo
echo "Application should be available at:"
echo -e "    http://${LB01_IP}\n"
echo "Security Notes:"
echo "  • Using non-root deploy user: $DEPLOY_USER"
echo "  • SSH key protected and validated"
echo "  • Files transferred via rsync (efficient & safe)"
echo "  • Proper permissions applied via sudo"
echo
echo "Next steps:"
echo "  1. Verify Nginx config on web servers"
echo "  2. Check HAProxy health checks"
echo "  3. Test the application thoroughly"

exit 0
