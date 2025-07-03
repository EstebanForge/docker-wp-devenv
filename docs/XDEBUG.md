# Xdebug Setup Guide

## Overview
This WordPress Docker environment includes Xdebug 3.x for PHP debugging with IDE integration.

## Configuration
- **Mode**: `debug` (step debugging enabled)
- **Trigger**: `XDEBUG_TRIGGER` (Chrome extension compatible)
- **Port**: `9003` (Xdebug 3.x default)
- **Host**: `host.docker.internal` (Docker Desktop)

## IDE Setup

### VS Code with PHP Debug Extension
1. Install "PHP Debug" extension
2. Create `.vscode/launch.json`:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}",
                "/var/www/html/wp-content": "${workspaceFolder}/src"
            }
        }
    ]
}
```

### PhpStorm
1. Go to Settings > PHP > Debug
2. Set Xdebug port to `9003`
3. Configure path mappings:
   - Local: `./src` → Remote: `/var/www/html/wp-content`
   - Local: `.` → Remote: `/var/www/html`

## Browser Extensions

### Chrome Xdebug Helper
1. Install "Xdebug helper" extension
2. Set IDE key to `XDEBUG_TRIGGER`
3. Click debug icon to start session

### Firefox Xdebug Helper
1. Install "Xdebug Helper for Firefox"
2. Configure with IDE key `XDEBUG_TRIGGER`

## Usage

### Start Debugging Session
1. Set breakpoints in your IDE
2. Start IDE debug listener
3. Enable Xdebug in browser extension
4. Visit your WordPress site
5. Debug session will pause at breakpoints

### Manual Trigger
Add `?XDEBUG_TRIGGER=1` to any URL:
```
http://wp.localhost/?XDEBUG_TRIGGER=1
http://wp.localhost/wp-admin/?XDEBUG_TRIGGER=1
```

### Cookie Trigger
Set cookie `XDEBUG_TRIGGER=XDEBUG_TRIGGER` for automatic debugging.

## File Mappings
- **WordPress Core**: Container `/var/www/html` → Host `.`
- **wp-content**: Container `/var/www/html/wp-content` → Host `./src`
- **Themes**: Container `/var/www/html/wp-content/themes` → Host `./src/themes`
- **Plugins**: Container `/var/www/html/wp-content/plugins` → Host `./src/plugins`

## Troubleshooting

### Connection Issues
```bash
# Check Xdebug is loaded
docker-compose exec wordpress php -m xdebug

# Check Xdebug configuration
docker-compose exec wordpress php -i | grep xdebug
```

### Port Conflicts
If port 9003 is busy, update in both:
- `php-conf/custom.ini`: `xdebug.client_port = 9004`
- `docker-compose.yml`: `"9004:9003"`

### Path Mapping Issues
Ensure your IDE path mappings match the container structure:
- Container paths start with `/var/www/html`
- Host paths are relative to project root

## Security Note
Xdebug is enabled only in development. For production:
- Remove Xdebug from Dockerfile
- Set `XDEBUG_MODE=off` in environment
