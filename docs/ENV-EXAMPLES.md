# Environment Configuration Examples

## Development Environment (.env)
```env
# WordPress Configuration
WP_DOMAIN=mysite.local
WP_TITLE=My Development Site
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=secure_dev_password
WP_ADMIN_EMAIL=dev@mysite.com

# WordPress Debug Configuration - DEVELOPMENT
WP_DEBUG=true
WP_DEBUG_LOG=true
WP_DEBUG_DISPLAY=true
SCRIPT_DEBUG=true
SAVEQUERIES=true

# MySQL Configuration
MYSQL_ROOT_PASSWORD=secure_root_password
MYSQL_USER=wp_user
MYSQL_PASSWORD=secure_wp_password
```

## Production Environment (.env.production)
```env
# WordPress Configuration
WP_DOMAIN=mysite.com
WP_TITLE=My Production Site
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=very_secure_production_password
WP_ADMIN_EMAIL=admin@mysite.com

# WordPress Debug Configuration - PRODUCTION
WP_DEBUG=false
WP_DEBUG_LOG=true
WP_DEBUG_DISPLAY=false
SCRIPT_DEBUG=false
SAVEQUERIES=false

# MySQL Configuration
MYSQL_ROOT_PASSWORD=very_secure_root_password
MYSQL_USER=wp_user
MYSQL_PASSWORD=very_secure_wp_password
```

## Debug Variables Explanation

### WP_DEBUG
- **Development**: `true` - Enables all WordPress debugging
- **Production**: `false` - Disables debug mode for security

### WP_DEBUG_LOG
- **Development**: `true` - Logs errors to `/wp-content/debug.log`
- **Production**: `true` - Still log errors but don't display them

### WP_DEBUG_DISPLAY
- **Development**: `true` - Shows errors on screen for debugging
- **Production**: `false` - Never show errors to users

### SCRIPT_DEBUG
- **Development**: `true` - Use unminified JS/CSS files
- **Production**: `false` - Use minified files for performance

### SAVEQUERIES
- **Development**: `true` - Log all database queries for debugging
- **Production**: `false` - Disable for performance

## Security Notes

1. **Never commit production credentials** to version control
2. **Use strong passwords** especially for production
3. **Rotate passwords regularly** in production environments
4. **Keep debug logs secure** and rotate them regularly
