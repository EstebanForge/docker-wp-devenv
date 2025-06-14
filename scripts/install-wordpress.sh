#!/bin/bash

# WordPress Installation Script for Docker Environment
# Handles WordPress core installation, user creation, and plugin/theme setup

set -e

echo "🚀 Starting WordPress installation..."

# Wait for database to be ready
echo "⏳ Waiting for database connection..."
while ! wp db check --allow-root --debug; do
  echo "   Database not ready, waiting 3 seconds..."
  sleep 3
done

echo "✅ Database connection established"

# Check if WordPress is already installed
if wp core is-installed --allow-root 2>/dev/null; then
  echo "ℹ️  WordPress already installed, skipping core installation"
else
  echo "📦 Installing WordPress core..." # Install WordPress
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  # Update URLs to use HTTPS
  HTTPS_URL=$(echo "${WP_URL}" | sed 's/http:/https:/')
  wp option update home "${HTTPS_URL}" --allow-root
  wp option update siteurl "${HTTPS_URL}" --allow-root

  echo "✅ WordPress core installed successfully"
fi

# Remove default plugins if they exist
echo "🗑️ Removing default plugins (Akismet, Hello Dolly)..."
wp plugin delete akismet --allow-root || echo "ℹ️  Akismet not found or already deleted."
wp plugin delete hello --allow-root || echo "ℹ️  Hello Dolly plugin (hello.php) not found or already deleted."
echo "✅ Default plugins processed."

# Activate all the plugins installed by Composer
wp plugin activate --all --allow-root

# Activate twentytwentyfive theme
wp theme activate twentytwentyfive --allow-root

# Configure WordPress settings
echo "⚙️  Configuring WordPress settings..."

# Set permalink structure
wp rewrite structure '/%year%/%postname%/' --allow-root

# Update site description
wp option update blogdescription "" --allow-root

# Set timezone
wp option update timezone_string "America/Santiago" --allow-root

# Disable comments on new posts
wp option update default_comment_status "closed" --allow-root

# Generate sample content for development
echo "📝 Creating sample content..."

# Update the default Sample Page (ID 2) to be 'Home'
if wp post get 2 --post_type=page --field=ID --allow-root >/dev/null 2>&1; then
  wp post update 2 --post_title="Home" --post_content="Welcome to the homepage." --post_status=publish --allow-root >/dev/null || echo "⚠️  Failed to update page ID 2 to 'Home'."
  echo "✅ Page ID 2 updated to 'Home'."
else
  echo "ℹ️  Page ID 2 not found. Creating a new page titled 'Home'."
  wp post create --post_type=page --post_title="Home" --post_content="Welcome to the homepage." --post_status=publish --allow-root >/dev/null || echo "⚠️  Failed to create 'Home' page."
fi

# Update the default "Hello world!" post (ID 1)
LOREM_IPSUM="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
if wp post get 1 --field=ID --allow-root >/dev/null 2>&1; then
  wp post update 1 --post_title="Hello Docker!" --post_content="${LOREM_IPSUM}" --post_status=publish --allow-root >/dev/null || echo "⚠️  Failed to update post ID 1."
  echo "✅ Post ID 1 updated to 'Hello Docker!' with lorem ipsum content."
else
  echo "ℹ️  Post ID 1 not found, skipping update. Creating a new 'Hello Docker!' post instead."
  wp post create --post_title="Hello Docker!" --post_content="${LOREM_IPSUM}" --post_status=publish --allow-root >/dev/null || echo "⚠️  Failed to create 'Hello Docker!' post."
fi

echo "🎉 WordPress installation completed successfully!"
echo ""
echo "📋 Installation Summary:"
echo "   Site URL: ${WP_URL}"
echo "   Admin User: ${WP_ADMIN_USER}"
echo "   Admin Email: ${WP_ADMIN_EMAIL}"
echo ""
echo "🔗 Access your site at: ${WP_URL}"
echo "🔧 Admin panel: ${WP_URL}/wp-admin/"
