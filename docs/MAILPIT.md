# Email Testing with Mailpit

## Overview

This development environment comes with [Mailpit](https://github.com/axllent/mailpit) pre-configured to capture all outgoing emails sent by WordPress. This allows you to test email functionality (e.g., contact forms, notifications, user registrations) without sending actual emails to external addresses.

Mailpit provides a clean web interface to view the emails your application sends, inspect headers, and see how they are rendered.

## How It Works

- A `mailpit` service is defined in the `docker-compose.yaml` file.
- The PHP-FPM container is configured to use a `sendmail_path` that pipes emails to a `catchmail` script.
- The `catchmail` script forwards the email to the Mailpit service running on the internal Docker network.

This setup ensures that any call to PHP's `mail()` function or WordPress's `wp_mail()` function is automatically intercepted.

## Accessing the Mailpit Web UI

Once the Docker environment is running, you can access the Mailpit interface in your browser at:

- **URL**: [http://localhost:8025](http://localhost:8025)

## How to Test Email Sending

Since the `wp mail` command is not a default part of WP-CLI, the most reliable way to test email sending from the command line is by using `wp eval` to execute the `wp_mail()` function directly.

### WP-CLI Test Command

Run the following command from your project root:

```bash
./wp eval "wp_mail('test@example.com', 'Mailpit Test', 'This is a test email from WordPress.');"
```

After running the command, refresh the Mailpit UI in your browser. You should see the new email appear in the inbox instantly.

### Testing Through WordPress

You can also trigger emails through the WordPress admin panel:

- Submitting a comment.
- Requesting a password reset.
- Using a contact form plugin.

All these actions should result in an email appearing in the Mailpit UI.
