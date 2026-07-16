#!/bin/sh
# Wrapper for PHP's sendmail_path. Delegates to catchmail (Ruby mail gem).
#
# We deliberately do NOT hardcode GEM_PATH here. A previous version pinned a
# Ruby 3.1.0 gem path, but the image ships Ruby 3.3.x (gems under .../3.3.0),
# so the override hid net-smtp and crashed every send with
# `Could not find 'net-smtp'`. Letting Ruby resolve its own default gem paths
# (via Gem.default_path / rubygems-integration) is version-agnostic and correct.

# Execute catchmail, passing along all arguments from PHP.
exec /usr/local/bin/catchmail "$@"
