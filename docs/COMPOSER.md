# Composer & WPackagist Integration

## Overview
This project uses Composer to manage WordPress plugins and themes via WPackagist, providing version control and dependency management for WordPress packages. It also includes WordPress core files for IDE support and autocompletion.

## Setup

### Install Composer Dependencies
```bash
# Install all dependencies (includes WordPress core for IDE)
composer install

# Install only production dependencies
composer install --no-dev
```

## IDE Support

### WordPress Core Autocompletion
The project includes:
- **WordPress Core** (`johnpbloch/wordpress-core`) - Full core files for IDE support
- **WordPress Stubs** (`php-stubs/wordpress-stubs`) - Function definitions for static analysis

This provides:
- ✅ Full WordPress function autocompletion
- ✅ Hook and filter suggestions
- ✅ Class and method documentation
- ✅ Static analysis support

## WPackagist Usage

### Installing Plugins
```bash
# Install specific plugin
composer require wpackagist-plugin/advanced-custom-fields

# Install multiple plugins
composer require wpackagist-plugin/contact-form-7 wpackagist-plugin/yoast-seo

# Install specific version
composer require wpackagist-plugin/elementor:^3.0
```

### Installing Themes
```bash
# Install theme
composer require wpackagist-theme/twentytwentyfive

# Install custom theme with version
composer require wpackagist-theme/storefront:^4.0
```

### Removing Packages
```bash
# Remove plugin
composer remove wpackagist-plugin/hello-dolly

# Remove theme
composer remove wpackagist-theme/twentytwentythree
```

## Development Tools

### Code Quality
```bash
# Run PHP CodeSniffer (WordPress standards)
composer run phpcs

# Fix coding standards automatically
composer run phpcbf

# Run PHPStan static analysis
composer run phpstan

# Run all quality checks
composer run quality
```

### Testing
```bash
# Run PHPUnit tests
composer run test
```

## Project Structure

Composer installs packages to:
- **Plugins**: `src/plugins/{plugin-name}/`
- **Themes**: `src/themes/{theme-name}/`
- **MU Plugins**: `src/mu-plugins/{plugin-name}/`

## Custom Development

### Custom Plugins/Themes
Create custom packages with `custom-` prefix:
```
src/
├── plugins/
│   ├── custom-api-plugin/     # Custom development (tracked in Git)
│   └── contact-form-7/        # WPackagist managed (ignored in Git)
└── themes/
    ├── custom-theme/          # Custom development (tracked in Git)
    └── twentytwentyfive/      # WPackagist managed (ignored in Git)
```

### Autoloading
Custom classes in MU plugins use PSR-4 autoloading:
```php
<?php
// File: src/mu-plugins/hypermedia-api/hypermedia-api.php

use ActitudStudio\WordPressDocker\Api\Controller;

$controller = new Controller();
```

## Best Practices

### Version Management
- **Lock specific versions** for production stability
- **Use semantic versioning** constraints (`^3.0`, `~2.1.0`)
- **Regular updates** with `composer update`

### Security
- **Never commit** `vendor/` directory
- **Commit** `composer.lock` for reproducible builds
- **Review updates** before deployment

### Workflow
1. **Add dependencies** via Composer
2. **Test locally** in Docker environment
3. **Commit** `composer.json` and `composer.lock`
4. **Deploy** with `composer install --no-dev`

## Docker Integration

The Docker environment automatically:
- Installs Composer dependencies during build
- Maps `src/` to WordPress `wp-content/`
- Handles file permissions correctly

## Example composer.json Additions

```json
{
    "require": {
        "wpackagist-plugin/advanced-custom-fields": "^6.0",
        "wpackagist-plugin/contact-form-7": "^5.8",
        "wpackagist-theme/twentytwentyfive": "^1.0"
    }
}
```
