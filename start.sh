#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}OpenCATS Startup Script${NC}"
echo -e "${GREEN}==================================${NC}"

# Fix Apache MPM configuration BEFORE starting Apache
echo -e "${YELLOW}Fixing Apache MPM configuration...${NC}"
echo "Disabling all MPMs..."
a2dismod mpm_event mpm_prefork mpm_worker 2>/dev/null || true
echo "Enabling mpm_prefork (required for PHP)..."
a2enmod mpm_prefork
echo -e "${GREEN}Apache MPM configuration fixed.${NC}"

# Now run database setup first
echo -e "${YELLOW}Running database setup...${NC}"
/usr/local/bin/docker-entrypoint.sh
SETUP_EXIT_CODE=$?

if [ $SETUP_EXIT_CODE -ne 0 ]; then
    echo -e "${YELLOW}Database setup completed with warnings, but continuing...${NC}"
fi

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Starting Apache in foreground...${NC}"
echo -e "${GREEN}==================================${NC}"

# Start Apache in foreground (this keeps the container running)
exec apache2-foreground
