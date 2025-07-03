# Esteban's WordPress Docker Development Environment

A production-ready WordPress development environment using Docker, optimized for Fedora Linux with SELinux support.

## Features

- **WordPress Latest** with PHP 8.3-FPM
- **MySQL 8.0** database
- **Nginx** reverse proxy with SSL support
- **WP-CLI** for command-line management
- **Local domain** support (wp.localhost by default)
- **SSL/HTTPS** with trusted local certificates
- **Environment-based configuration**
- **SELinux compatible** (Fedora/RHEL) - uses `:Z` volume flags and a permission script.
- **Auto-installation** with dummy content, with Akismet and Hello Dolly plugins automatically removed.
- **Email Testing with Mailpit** - Captures all outgoing emails for easy debugging.

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Linux with sudo access
- Basic utilities: `openssl`, `envsubst` (gettext package)

### Installation

1. **Clone/Download** this repository
2. **Run the setup script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
3. **Follow the interactive prompts** to configure:
   - Local domain (e.g., wp.localhost)
   - WordPress admin credentials
   - Database passwords
   - Performance settings

4. **Start the environment**:
   ```bash
   chmod +x start # Make sure it's executable (run once)
   ./start        # Starts services in detached mode by default
   ```
   This script will start the Docker containers and then automatically run a sub-script (`./scripts/set-src-permissions.sh`) to configure necessary host permissions for the `./src` directory, ensuring compatibility with SELinux and shared write access.

5. **Access your site**: http://your-domain.localhost

### Manual Setup (Alternative)

If you prefer to set up manually without the interactive script:

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Edit configuration**:
   ```bash
   # Edit .env file with your preferred settings
   nano .env
   ```

3. **Run individual setup scripts**:
   ```bash
   chmod +x scripts/setup-fedora.sh scripts/generate-nginx-config.sh scripts/setup-local-domain.sh
   ./scripts/setup-fedora.sh
   ./scripts/generate-nginx-config.sh
   ./scripts/setup-local-domain.sh
   ```

4. **Start containers**:
   ```bash
   docker-compose up -d
   ```

5. **Set Host Permissions for `./src`**:
   After the containers are running, especially on SELinux systems like Fedora, set the correct permissions for the `./src` directory:
   ```bash
   chmod +x ./scripts/set-src-permissions.sh
   ./scripts/set-src-permissions.sh
   ```

### What the Setup Does

The setup script will:
- ✅ Check system dependencies
- ✅ Collect your configuration preferences
- ✅ Generate secure passwords
- ✅ Create `.env` file with your settings
- ✅ Set up directory structure with proper permissions
- ✅ Configure SELinux contexts (Fedora/RHEL)
- ✅ Generate Nginx configuration
- ✅ Set up local DNS mapping
- ✅ Create WordPress installation script

## Directory Structure

```
.
├── src/                    # WordPress wp-content (mapped to host)
│   ├── themes/            # Custom themes
│   ├── plugins/           # Custom plugins
│   ├── uploads/           # Media uploads
│   └── mu-plugins/        # Must-use plugins
├── docs/                  # Documentation
│   ├── ENV-EXAMPLES.md    # Environment configuration examples
│   ├── PERMISSIONS.md     # File permissions guide
│   └── XDEBUG.md         # Xdebug setup and usage
├── scripts/               # Setup and utility scripts
│   ├── setup-fedora.sh   # Fedora-specific setup
│   ├── generate-nginx-config.sh  # Nginx config generator
│   ├── setup-local-domain.sh     # Local DNS setup
│   ├── install-wordpress.sh      # WordPress installation script (also removes Akismet & Hello Dolly)
│   └── set-src-permissions.sh  # Sets host permissions for ./src directory
├── php-conf/              # PHP configuration
├── nginx-conf/            # Nginx configuration (also stores generated SSL certs)
├── docker-compose.yml    # Docker services
├── .env.example          # Environment configuration template
├── setup              # First-time setup script
└── start              # Recommended script to start environment and set permissions
```

## Environment Configuration

All settings are managed through the `.env` file:

```env
# WordPress Configuration
WP_DOMAIN=wp.localhost
WP_TITLE=My WordPress Site
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=secure_password
WP_ADMIN_EMAIL=admin@example.com

# Debug Settings (Development)
WP_DEBUG=true
WP_DEBUG_LOG=true
WP_DEBUG_DISPLAY=true

# Performance
WP_MEMORY_LIMIT=256M
```

## Email Testing with Mailpit

This environment uses **Mailpit** to intercept all outgoing emails from WordPress. You can view any email sent by the application by visiting the Mailpit web interface:

- **URL**: [http://localhost:8025](http://localhost:8025)

This is incredibly useful for testing contact forms, user notifications, and other email-related features without spamming real inboxes. For more details, see the [Mailpit documentation](./docs/MAILPIT.md).

## Useful Commands

### Docker Management
```bash
# Start environment (recommended method)
# (Make sure it's executable: chmod +x start)
./start          # Starts services in detached mode by default

# To pass arguments (e.g., build, specific services, or run in foreground):
./start --build              # Builds images and starts in detached mode (due to default)
./start --build -d           # Explicitly detached with build
./start up                   # Starts in foreground (passing 'up' as an arg)
./start wordpress webserver  # Starts specific services (will be detached by default if no other args prevent it)
                                # If you want specific services in foreground: ./start wordpress webserver up (or similar non-detaching arg)

# If you need to use docker-compose directly (e.g., for specific sub-commands not covered by start):
# docker-compose up -d

# Stop environment
docker-compose down

# View logs
docker-compose logs -f

# Restart services
docker-compose restart
```

### WP-CLI Usage
```bash
# Run WP-CLI commands
./wp <command>

# Examples:
./wp plugin list
./wp user list
./wp core version
```

### Development Workflow
```bash
# Edit themes/plugins directly in ./src/
# Changes are immediately reflected

# Install plugins via WP-CLI
docker-compose exec wpcli wp plugin install contact-form-7 --activate

# Or via WordPress admin at http://your-domain.localhost/wp-admin
```

## Security Notes

- **Strong passwords** are generated automatically
- **Debug mode** is enabled for development (disable for production)
- **File permissions** are set for WordPress compatibility
- **SELinux contexts** are properly configured
- **Local development only** - not production-ready as-is

## Troubleshooting

### Permission Issues
If you encounter permission issues with the `./src` directory (e.g., WordPress can't write to `uploads`, or you can't write to plugin/theme files from the host), run the dedicated script:
```bash
./scripts/set-src-permissions.sh
```
This script is designed to set appropriate ownership for your host user and apply ACLs (or standard permissions as a fallback) for the `www-data` group used by WordPress inside the container. It's also called automatically if you use `./start`.

### SELinux Issues (Fedora/RHEL)
The Docker Compose configuration uses the `:Z` flag for the `./src` volume mount (`./src:/var/www/html/wp-content:Z`), which tells Docker to relabel the host directory so the container can use it with SELinux.

Additionally, the `./scripts/set-src-permissions` script (run automatically by `./start`) further helps by setting appropriate file ACLs (Access Control Lists) or standard Unix permissions that work well with SELinux and allow shared write access between your host user and the `www-data` user in the container.

If you still encounter SELinux denials related to `./src`:
```bash
# Check SELinux denials
sudo ausearch -m avc -ts recent

# You can try to manually relabel if needed, though :Z and the script should handle it
# sudo restorecon -R src/
```

### Domain Access Issues
```bash
# Check hosts file
grep "your-domain.localhost" /etc/hosts

# Add domain manually if needed
echo "127.0.0.1 your-domain.localhost" | sudo tee -a /etc/hosts
```

## Customization

### Change Domain
1. Update `WP_DOMAIN` in `.env`
2. Regenerate configs: `./generate-nginx-config.sh`
3. Update hosts: `./setup-local-domain.sh`
4. Restart: `docker-compose restart`

### Add Custom PHP Settings
Edit `php-conf/custom.ini` and restart containers.

### Modify Nginx Configuration
Edit `nginx-conf/nginx.conf` and restart webserver.

## Production Deployment

You shouldn't use this for production. Period.

It is meant to be used for local development and testing only.

## Support

This environment is optimized for:
- **Fedora 42+** with SELinux or **Ubuntu/Debian** (basic support)
- **WordPress plugin/theme development**

## Documentation

Additional documentation is available in the `./docs/` folder:

- **[Environment Configuration](./docs/ENV-EXAMPLES.md)** - Development vs production settings
- **[File Permissions](./docs/PERMISSIONS.md)** - WordPress and host permissions guide
- **[Xdebug Setup](./docs/XDEBUG.md)** - PHP debugging configuration and usage
- **[Composer & WPackagist](./docs/COMPOSER.md)** - WordPress package management
- **[WP-CLI Integration](./docs/WP-CLI.md)** - WordPress CLI commands via Docker
- **[Mailpit for Email Testing](./docs/MAILPIT.md)** - Guide to capturing and viewing emails locally
- **[SSL Configuration](./docs/SSL.md)** - HTTPS setup with trusted certificates (certs stored in ./nginx-conf/)
