# WordPress Docker Permissions Guide

## Directory Structure & Permissions

```
./src/                    # 775 (drwxrwxr-x)
├── themes/              # 775 (drwxrwxr-x) - WordPress can install themes
├── plugins/             # 775 (drwxrwxr-x) - WordPress can install plugins
├── uploads/             # 775 (drwxrwxr-x) - WordPress uploads media
└── mu-plugins/          # 775 (drwxrwxr-x) - Must-use plugins
```

## Write Access Matrix

### WordPress Container CAN Write To:
- ✅ `/src/uploads/` - Media uploads, thumbnails
- ✅ `/src/plugins/` - Plugin installations via admin
- ✅ `/src/themes/` - Theme installations via admin
- ✅ `/src/` - WordPress config cache files
- ✅ Any subdirectories within above

### Your Local User CAN:
- ✅ Read/Write all files in `/src/`
- ✅ Create/modify themes in `/src/themes/`
- ✅ Create/modify plugins in `/src/plugins/`
- ✅ Access uploaded files in `/src/uploads/`
- ✅ Version control custom code

## WordPress Functions That Will Work:

### File Operations:
```php
// These will work with FS_METHOD = 'direct'
wp_upload_dir();           // Uploads to /src/uploads/
wp_mkdir_p();             // Create directories
file_put_contents();      // Write files
copy(), rename(), unlink(); // File operations
```

### Plugin/Theme Management:
```php
// Admin can install/update
install_plugin();
activate_plugin();
switch_theme();
wp_get_themes();
```

### Media Handling:
```php
wp_handle_upload();       // File uploads
wp_generate_attachment_metadata(); // Image processing
image_resize();           // Thumbnail generation
```

## Permission Troubleshooting:

### If WordPress can't write:
```bash
# Fix ownership
sudo chown -R 1000:1000 src/

# Fix permissions
sudo chmod -R 775 src/
sudo chmod -R 664 src/**/*.php
```

### If you can't write locally:
```bash
# Add yourself to group 1000 (if needed)
sudo usermod -aG $(id -gn 1000) $USER

# Or fix ownership back to you
sudo chown -R $USER:$USER src/
```

## SELinux Considerations:

The `:Z` flag in docker-compose ensures:
- Container can read/write mounted volumes
- SELinux contexts are properly set
- No denials for file operations

## Best Practices:

1. **Development**: Work directly in `/src/themes/` and `/src/plugins/`
2. **WordPress Admin**: Use for plugin/theme installations
3. **Uploads**: Let WordPress handle via admin or WP-CLI
4. **Version Control**: Track custom themes/plugins, ignore uploads
