#!/bin/bash

echo "=== PHP Container Starting ==="
echo "Starting PHP-FPM immediately to prevent 502 errors..."

# Start PHP-FPM in background
php-fpm &
PHP_FPM_PID=$!

echo "PHP-FPM started with PID: $PHP_FPM_PID"
echo "Container ready to serve requests"

# WordPress setup in background (non-blocking)
(
  export PATH=/usr/local/bin:$PATH
  sleep 10  # Give PHP-FPM time to fully start

  echo "=== Background WordPress Setup ==="

  # Wait for database to be ready
  echo "Waiting for database..."
  while ! wp db check --allow-root >/dev/null 2>&1; do
    echo "Database not ready, waiting..."
    sleep 5
  done
  echo "Database ready"

  # Check if WordPress is already installed
  if wp core is-installed --allow-root >/dev/null 2>&1; then
    echo "✅ WordPress already installed"
  else
    echo "📦 Installing WordPress..."

    # Show detailed output for debugging
    echo "Running: wp core install --url=${WP_URL:-https://test.localhost} --title='${WP_TITLE:-Test Site}' --admin_user=${WP_ADMIN_USER:-admin} --admin_password=${WP_ADMIN_PASSWORD:-password} --admin_email=${WP_ADMIN_EMAIL:-admin@test.localhost} --skip-email --allow-root"

    if wp core install \
      --url="${WP_URL:-https://test.localhost}" \
      --title="${WP_TITLE:-Test Site}" \
      --admin_user="${WP_ADMIN_USER:-admin}" \
      --admin_password="${WP_ADMIN_PASSWORD:-password}" \
      --admin_email="${WP_ADMIN_EMAIL:-admin@test.localhost}" \
      --skip-email \
      --allow-root 2>&1; then

      echo "✅ WordPress installed successfully"

      # Update URLs and cleanup
      HTTPS_URL=$(echo "${WP_URL:-https://test.localhost}" | sed 's/http:/https:/')
      wp option update home "$HTTPS_URL" --allow-root >/dev/null 2>&1
      wp option update siteurl "$HTTPS_URL" --allow-root >/dev/null 2>&1
      wp plugin delete akismet hello --allow-root >/dev/null 2>&1

      echo "🎉 WordPress setup complete!"
    else
      echo "❌ WordPress installation failed - see output above"
    fi
  fi
) > /tmp/wp-install.log 2>&1 &

# Keep PHP-FPM running
wait $PHP_FPM_PID
