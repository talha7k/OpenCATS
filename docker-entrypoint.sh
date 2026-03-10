#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}OpenCATS Docker Entrypoint${NC}"
echo "=================================="

# Function to wait for MySQL/MariaDB to be ready
wait_for_mysql() {
    echo -e "${YELLOW}Waiting for MySQL to be ready...${NC}"

    max_attempts=30
    attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if mysql -h"${DATABASE_HOST}" -u"${DATABASE_USER}" -p"${DATABASE_PASS}" -e "SELECT 1" > /dev/null 2>&1; then
            echo -e "${GREEN}MySQL is ready!${NC}"
            return 0
        fi

        attempt=$((attempt + 1))
        echo "Attempt $attempt/$max_attempts: Waiting for MySQL..."
        sleep 2
    done

    echo -e "${RED}Failed to connect to MySQL after $max_attempts attempts${NC}"
    exit 1
}

# Function to check if database is already initialized
is_database_initialized() {
    # Check if the config table exists and has data
    result=$(mysql -h"${DATABASE_HOST}" -u"${DATABASE_USER}" -p"${DATABASE_PASS}" -D"${DATABASE_NAME}" -e "SHOW TABLES LIKE 'config';" 2>&1)
    if [[ $result == *"config"* ]]; then
        return 0  # Database is initialized
    fi
    return 1  # Database is not initialized
}

# Function to initialize database
initialize_database() {
    echo -e "${YELLOW}Initializing database...${NC}"

    # Create database if it doesn't exist
    mysql -h"${DATABASE_HOST}" -u"${DATABASE_USER}" -p"${DATABASE_PASS}" -e "CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

    # Import the schema
    if [ -f "/var/www/html/db/cats_schema.sql" ]; then
        echo "Importing cats_schema.sql..."
        mysql -h"${DATABASE_HOST}" -u"${DATABASE_USER}" -p"${DATABASE_PASS}" "${DATABASE_NAME}" < /var/www/html/db/cats_schema.sql
        echo -e "${GREEN}Database schema imported successfully!${NC}"
    else
        echo -e "${RED}Error: db/cats_schema.sql not found!${NC}"
        exit 1
    fi

    echo -e "${GREEN}Database initialization complete!${NC}"
}

# Function to generate config.php from environment variables
generate_config() {
    echo -e "${YELLOW}Generating config.php from environment variables...${NC}"

    # If config.php doesn't exist, create it from the template
    if [ ! -f "/var/www/html/config.php" ]; then
        if [ -f "/var/www/html/config.php.example" ]; then
            cp /var/www/html/config.php.example /var/www/html/config.php
        else
            # Create a minimal config.php
            cat > /var/www/html/config.php << 'EOF'
<?php
/* License key. */
define('LICENSE_KEY','PLACEHOLDER_LICENSE_KEY');

/* legacy root. */
if( !defined('LEGACY_ROOT') )
{
    define('LEGACY_ROOT', '.');
}

/* Database configuration. */
define('DATABASE_USER', 'PLACEHOLDER_DB_USER');
define('DATABASE_PASS', 'PLACEHOLDER_DB_PASS');
define('DATABASE_HOST', 'PLACEHOLDER_DB_HOST');
define('DATABASE_NAME', 'PLACEHOLDER_DB_NAME');

/* Authentication Configuration
 * Options are sql, ldap, sql+ldap
 */
define ('AUTH_MODE', 'sql');

/* Resfly.com Resume Import Services Enabled */
define('PARSING_ENABLED', false);

/* If you have an SSL compatible server, you can enable SSL for all of CATS. */
define('SSL_ENABLED', false);

/* Text parser settings. */
define('ANTIWORD_PATH', "\\path\\to\\antiword");
define('ANTIWORD_MAP', '8859-1.txt');

/* XPDF / pdftotext settings. */
define('PDFTOTEXT_PATH', "\\path\\to\\pdftotext");

/* html2text settings. */
define('HTML2TEXT_PATH', "\\path\\to\\html2text");

/* UnRTF settings. */
define('UNRTF_PATH', "\\path\\to\unrtf");

/* Temporary directory. */
define('CATS_TEMP_DIR', './temp');

/* If User Details and Login Activity pages in the settings module are
 * unbearably slow, set this to false.
 */
define('ENABLE_HOSTNAME_LOOKUP', false);

/* CATS can optionally use Sphinx to speed up document searching. */
define('ENABLE_SPHINX', false);
define('SPHINX_API', './lib/sphinx/sphinxapi.php');
define('SPHINX_HOST', 'localhost');
define('SPHINX_PORT', 3312);
define('SPHINX_INDEX', 'cats catsdelta');

/* Pager settings. */
define('CONTACTS_PER_PAGE',      15);
define('CANDIDATES_PER_PAGE',    15);
define('CLIENTS_PER_PAGE',       15);
define('LOGIN_ENTRIES_PER_PAGE', 15);

/* Maximum number of characters of the owner/recruiter users' last names
 * to show before truncating.
 */
define('LAST_NAME_MAXLEN', 6);

/* Length of resume excerpts displayed in Search Candidates results. */
define('SEARCH_EXCERPT_LENGTH', 256);

/* Number of MRU list items. */
define('MRU_MAX_ITEMS', 5);

/* MRU item length. */
define('MRU_ITEM_LENGTH', 20);

/* Number of recent search items. */
define('RECENT_SEARCH_MAX_ITEMS', 5);

/* HTML Encoding. */
define('HTML_ENCODING', 'UTF-8');

/* AJAX Encoding. */
define('AJAX_ENCODING', 'UTF-8');

/* SQL Character Set. */
define('SQL_CHARACTER_SET', 'utf8');

/* Insert BOM in the beginning of CSV file */
define('INSERT_BOM_CSV_LENGTH', '3');
define('INSERT_BOM_CSV_1', '239');
define('INSERT_BOM_CSV_2', '187');
define('INSERT_BOM_CSV_3', '191');
define('INSERT_BOM_CSV_4', '');

/* Path to modules. */
define('MODULES_PATH', './modules/');

/* Unique session name. */
define('CATS_SESSION_NAME', 'CATS');

/* Subject line of e-mails sent to candidates via the career portal when they
 * apply for a job order.
 */
define('CAREERS_CANDIDATEAPPLY_SUBJECT', 'Thank You for Your Application');

/* Subject line of e-mails sent to job order owners via the career portal when
 * they apply for a job order.
 */
define('CAREERS_OWNERAPPLY_SUBJECT', 'CATS - A Candidate Has Applied to Your Job Order');

/* Subject line of e-mails sent to candidates when their status changes for a
 * job order.
 */
define('CANDIDATE_STATUSCHANGE_SUBJECT', 'Job Application Status Change');

/* Password request settings. */
define('FORGOT_PASSWORD_FROM_NAME', 'CATS');
define('FORGOT_PASSWORD_SUBJECT',   'CATS - Password Retrieval Request');
define('FORGOT_PASSWORD_BODY',      'You recently requested that your OpenCATS: Applicant Tracking System password be sent to you. Your current password is %s.');

/* Is this a demo site? */
define('ENABLE_DEMO_MODE', false);

/* Offset to GMT Time. */
define('OFFSET_GMT', 2);

/* Should we enforce only one session per user (excluding demo)? */
define('ENABLE_SINGLE_SESSION', false);

/* Automated testing. */
define('TESTER_LOGIN',     'john@mycompany.net');
define('TESTER_PASSWORD',  'john99');
define('TESTER_FIRSTNAME', 'John');
define('TESTER_LASTNAME',  'Anderson');
define('TESTER_FULLNAME',  'John Anderson');
define('TESTER_USER_ID',   4);

/* Demo login. */
define('DEMO_LOGIN',     'john@mycompany.net');
define('DEMO_PASSWORD',  'john99');

/* Mail settings. */
define('MAIL_MAILER', 3);
define('MAIL_SENDMAIL_PATH', "/usr/sbin/sendmail");
define('MAIL_SMTP_HOST', "localhost");
define('MAIL_SMTP_PORT', 587);
define('MAIL_SMTP_AUTH', true);
define('MAIL_SMTP_USER', "user");
define('MAIL_SMTP_PASS', "password");
define('MAIL_SMTP_SECURE', "tls");

/* Event reminder E-Mail Template. */
$GLOBALS['eventReminderEmail'] = <<<EOF
%FULLNAME%,

This is a reminder from the OpenCATS Applicant Tracking System about an
upcoming event.

'%EVENTNAME%'
Is scheduled to occur %DUETIME%.

Description:
%NOTES%

--
OPENCATS Applicant Tracking System
EOF;

/* Enable replication slave mode? */
define('CATS_SLAVE', false);

/* Cache modules? */
define('CACHE_MODULES', false);

/* US zipcode database? */
define('US_ZIPS_ENABLED', false);

/* LDAP Configuration */
define ('LDAP_HOST', 'ldap.forumsys.com');
define ('LDAP_PORT', '389');
define ('LDAP_PROTOCOL_VERSION', 3);
define ('LDAP_BASEDN', 'dc=example,dc=com');
define ('LDAP_BIND_DN', 'cn=read-only-admin,dc=example,dc=com');
define ('LDAP_BIND_PASSWORD', 'password');
define ('LDAP_ACCOUNT', 'cn={$username},dc=example,dc=com');
define ('LDAP_ATTRIBUTE_UID', 'uid');
define ('LDAP_ATTRIBUTE_DN', 'dn');
define ('LDAP_ATTRIBUTE_LASTNAME', 'sn');
define ('LDAP_ATTRIBUTE_FIRSTNAME', 'givenname');
define ('LDAP_ATTRIBUTE_EMAIL', 'mail');
define ('LDAP_SITEID', 1);
define ('LDAP_AD', false);

/* Require constants.php */
require_once(LEGACY_ROOT . '/constants.php');

?>
EOF
        fi
    fi

    # Use sed to replace values - works on both Alpine and Debian
    # The syntax -i.bak creates a backup, then we remove it. This is compatible with both systems.
    sed -i.bak "s|PLACEHOLDER_LICENSE_KEY|${LICENSE_KEY}|g" /var/www/html/config.php
    sed -i.bak "s|PLACEHOLDER_DB_USER|${DATABASE_USER}|g" /var/www/html/config.php
    sed -i.bak "s|PLACEHOLDER_DB_PASS|${DATABASE_PASS}|g" /var/www/html/config.php
    sed -i.bak "s|PLACEHOLDER_DB_HOST|${DATABASE_HOST}|g" /var/www/html/config.php
    sed -i.bak "s|PLACEHOLDER_DB_NAME|${DATABASE_NAME}|g" /var/www/html/config.php

    # Remove the backup file created by sed
    rm -f /var/www/html/config.php.bak

    echo -e "${GREEN}config.php generated successfully!${NC}"
}

# Function to set proper permissions
set_permissions() {
    echo -e "${YELLOW}Setting proper file permissions...${NC}"

    # Set ownership
    chown -R www-data:www-data /var/www/html/temp
    chown -R www-data:www-data /var/www/html/upload
    chown -R www-data:www-data /var/www/html/attachments

    # Set permissions
    chmod -R 755 /var/www/html/temp
    chmod -R 755 /var/www/html/upload
    chmod -R 755 /var/www/html/attachments

    # Make sure config.php is readable
    chmod 644 /var/www/html/config.php

    echo -e "${GREEN}Permissions set successfully!${NC}"
}

# Main execution flow
main() {
    # Validate required environment variables
    if [ -z "${DATABASE_HOST}" ] || [ -z "${DATABASE_USER}" ] || [ -z "${DATABASE_NAME}" ]; then
        echo -e "${RED}Error: Required environment variables not set!${NC}"
        echo "Required: DATABASE_HOST, DATABASE_USER, DATABASE_NAME"
        exit 1
    fi

    # Set defaults
    export DATABASE_PASS="${DATABASE_PASS:-}"
    export LICENSE_KEY="${LICENSE_KEY:-3163GQ-54ISGW-14E4SHD-ES9ICL-X02DTG-GYRSQ6}"

    echo "Database Host: ${DATABASE_HOST}"
    echo "Database Name: ${DATABASE_NAME}"
    echo "Database User: ${DATABASE_USER}"
    echo "License Key: ${LICENSE_KEY}"

    # Wait for MySQL to be ready
    wait_for_mysql

    # Generate config.php
    generate_config

    # Check if database is initialized
    if is_database_initialized; then
        echo -e "${GREEN}Database already initialized. Skipping schema import.${NC}"
    else
        # Initialize database
        initialize_database
    fi

    # Set proper permissions
    set_permissions

    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}OpenCATS initialization complete!${NC}"
    echo -e "${GREEN}==================================${NC}"
}

# Run main function
main

# Execute the command passed to the container
exec "$@"
