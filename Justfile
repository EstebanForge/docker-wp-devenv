default:
    @just --list

# Check shell scripts syntax
check:
    bash -n devenv wp lib/*.sh scripts/*.sh

# Start containers (detached)
up *args:
    ./devenv start {{args}}

# Stop containers
down *args:
    ./devenv stop {{args}}

# Restart containers
restart *args:
    ./devenv restart {{args}}

# Show container status
status:
    ./devenv status

# Follow container logs
logs *args:
    ./devenv logs {{args}}

# Run WP-CLI inside container
wp *args:
    ./wp {{args}}

# Local CI check
ci: check
