#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}OpenCATS Docker Entrypoint${NC}"
echo "=================================="
echo "Timestamp: $(date)"

# Create healthcheck.php IMMEDIATELY - before anything else
echo -e "${YELLOW}Creating healthcheck.php immediately...${NC}"
cat > /var/www/html/healthcheck.php << 'EOF'
<?php
header('Content-Type: text/plain');
echo "OK";
?>
EOF
chmod 644 /var/www/html/healthcheck.php
echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] healthcheck.php created!${NC}"

# Fix Apache MPM conflict
echo -e "${YELLOW}Checking Apache MPM configuration...${NC}"
MPM_LOADED=$(ls /etc/apache2/mods-enabled/mpm_*.load 2>/dev/null | wc -l)

if [ "$MPM_LOADED" -gt 1 ]; then
    echo -e "${RED}Multiple MPMs detected. Fixing...${NC}"
    a2dismod mpm_event mpm_prefork mpm_worker 2>/dev/null || true
    a2enmod mpm_prefork
    echo -e "${GREEN}MPM conflict resolved.${NC}"
else
    echo -e "${GREEN}MPM configuration is correct.${NC}"
fi

# Function to generate config.php from environment variables
generate_config() {
    echo -e "${YELLOW}Generating config.php...${NC}"

    if [ ! -f "/var/www/html/config.php" ] || [ ! -s "/var/www/html/config.php" ]; then
        if [ -f "/var/www/html/config.php.example" ]; then
            cp /var/www/html/config.php.example /var/www/html/config.php
        fi
    fi

    # Update config.php with environment variables
    if [ -f "/var/www/html/config.php" ]; then
        sed -i.bak "s|define('DATABASE_USER', '.*')|define('DATABASE_USER', '${DATABASE_USER}')|g" /var/www/html/config.php
        sed -i.bak "s|define('DATABASE_PASS', '.*')|define('DATABASE_PASS', '${DATABASE_PASS}')|g" /var/www/html/config.php
        sed -i.bak "s|define('DATABASE_HOST', '.*')|define('DATABASE_HOST', '${DATABASE_HOST}')|g" /var/www/html/config.php
        sed -i.bak "s|define('DATABASE_NAME', '.*')|define('DATABASE_NAME', '${DATABASE_NAME}')|g" /var/www/html/config.php
        sed -i.bak "s|define('LICENSE_KEY','.*')|define('LICENSE_KEY','${LICENSE_KEY}')|g" /var/www/html/config.php
        rm -f /var/www/html/config.php.bak*
        echo -e "${GREEN}config.php generated!${NC}"
    fi
}

# Function to set proper permissions
set_permissions() {
    echo -e "${YELLOW}Setting permissions...${NC}"
    chown -R www-data:www-data /var/www/html/temp 2>/dev/null || true
    chown -R www-data:www-data /var/www/html/upload 2>/dev/null || true
    chown -R www-data:www-data /var/www/html/attachments 2>/dev/null || true
    chmod -R 755 /var/www/html/temp 2>/dev/null || true
    chmod -R 755 /var/www/html/upload 2>/dev/null || true
    chmod -R 755 /var/www/html/attachments 2>/dev/null || true
    chmod 644 /var/www/html/config.php 2>/dev/null || true
    echo -e "${GREEN}Permissions set!${NC}"
}

# Main execution flow - Simplified for Railway
main() {
    # Set defaults
    export DATABASE_PASS="${DATABASE_PASS:-}"
    export LICENSE_KEY="${LICENSE_KEY:-3163GQ-54ISGW-14E4SHD-ES9ICL-X02DTG-GYRSQ6}"

    echo "Configuration:"
    echo "  Database Host: ${DATABASE_HOST:-not set}"
    echo "  Database Name: ${DATABASE_NAME:-not set}"
    echo "  Database User: ${DATABASE_USER:-not set}"

    # Generate config.php if variables are set
    if [ -n "${DATABASE_HOST}" ] && [ -n "${DATABASE_USER}" ] && [ -n "${DATABASE_NAME}" ]; then
        generate_config
    else
        echo -e "${YELLOW}Database variables not set. Installation wizard will handle setup.${NC}"
    fi

    # Set proper permissions
    set_permissions

    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}OpenCATS ready!${NC}"
    echo -e "${GREEN}Visit the installation wizard to set up the database.${NC}"
    echo -e "${GREEN}==================================${NC}"

    return 0
}

# Run main function
main
exit $?
