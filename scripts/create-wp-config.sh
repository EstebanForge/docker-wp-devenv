#!/bin/bash

# WordPress Configuration Generator Script
# Creates wp-config.php with proper database and WordPress settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

WP_CONFIG_PATH="src/wp-core/wp-config.php"
ENV_FILE=".env"

# Helper functions
print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
  print_error ".env file not found! Please run ./setup first."
  exit 1
fi

# Load environment variables
set -a
source "$ENV_FILE"
set +a

# Set defaults if variables are not set
MYSQL_USER="${MYSQL_USER:-wordpress_user}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-wordpress_pass}"
WP_DOMAIN="${WP_DOMAIN:-test.localhost}"
WP_TITLE="${WP_TITLE:-${WP_DOMAIN}}"
WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-password}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@${WP_DOMAIN}}"

# Check if wp-config.php already exists
if [ -f "$WP_CONFIG_PATH" ]; then
  print_warning "wp-config.php already exists at $WP_CONFIG_PATH"
  echo -n "Do you want to overwrite it? (y/N): "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_success "Keeping existing wp-config.php"
    exit 0
  fi
fi

echo "📝 Creating wp-config.php..."

# Generate WordPress authentication keys
echo "🔐 Generating WordPress authentication keys..."
AUTH_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Create wp-config.php with proper PHP syntax
cat > "$WP_CONFIG_PATH" <<EOF
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the website, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', '${MYSQL_USER}' );

/** Database password */
define( 'DB_PASSWORD', '${MYSQL_PASSWORD}' );

/** Database hostname */
define( 'DB_HOST', 'db' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
${AUTH_KEYS}

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/
 */
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'SCRIPT_DEBUG', true );
define( 'SAVEQUERIES', true );

/* Add any custom values between this line and the "stop editing" line. */

define('WP_HOME', 'https://${WP_DOMAIN}');
define('WP_SITEURL', 'https://${WP_DOMAIN}');
define('FS_METHOD', 'direct');

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOF

print_success "wp-config.php created successfully at $WP_CONFIG_PATH"
print_success "Database: wordpress (user: ${MYSQL_USER})"
print_success "Domain: https://${WP_DOMAIN}"
