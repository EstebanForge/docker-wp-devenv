#!/bin/bash
# Wrapper script to run docker-compose up and then set source permissions.

set -e # Exit immediately if a command exits with a non-zero status.

# Detect OS and start the appropriate container runtime if not already running
_wait_for_docker() {
  for _ in {1..15}; do
    if docker info >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

if ! docker info >/dev/null 2>&1; then
  echo "🔄 Container daemon is not running. Attempting to start..."
  _os="$(uname -s)"

  if [[ "$_os" == "Darwin" ]]; then
    # macOS: prefer OrbStack, fall back to Docker Desktop
    if [[ -d "/Applications/OrbStack.app" ]]; then
      echo "   Detected OrbStack — launching..."
      open -a OrbStack
    else
      echo "   Launching Docker Desktop..."
      open -a Docker
    fi
    if _wait_for_docker; then
      echo "   Daemon ready."
    else
      echo "🔴 Error: Daemon did not become ready in time. Please start it manually."
      exit 1
    fi

  elif [[ "$_os" == "Linux" ]]; then
    # Linux: prefer Podman (Docker-compat socket), fall back to Docker via systemctl
    if command -v podman >/dev/null 2>&1; then
      echo "   Detected Podman — starting podman socket..."
      # Enable and start the user-level Docker-compat socket (rootless)
      if systemctl --user enable --now podman.socket 2>/dev/null; then
        # Point Docker CLI at Podman's socket for this session
        export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
        echo "   DOCKER_HOST set to Podman socket: ${DOCKER_HOST}"
      else
        # Fallback: start the system-level Podman socket
        sudo systemctl enable --now podman.socket 2>/dev/null || true
        export DOCKER_HOST="unix:///run/podman/podman.sock"
        echo "   DOCKER_HOST set to system Podman socket: ${DOCKER_HOST}"
      fi
      if _wait_for_docker; then
        echo "   Podman daemon ready."
      else
        echo "🔴 Error: Podman daemon did not become ready in time. Please start it manually."
        exit 1
      fi
    elif command -v systemctl >/dev/null 2>&1; then
      echo "   Starting Docker via systemctl..."
      if sudo systemctl start docker; then
        if _wait_for_docker; then
          echo "   Docker daemon started via systemctl."
        else
          echo "🔴 Error: Docker daemon did not start successfully."
          exit 1
        fi
      else
        echo "🔴 Error: Failed to start Docker daemon with systemctl."
        exit 1
      fi
    else
      echo "🔴 Error: No container runtime found. Install Docker or Podman and try again."
      exit 1
    fi

  else
    echo "🔴 Error: Unsupported OS '${_os}'. Please start your container daemon manually."
    exit 1
  fi
fi

# Get the directory where this script is located (should be project root)
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PERMISSION_SCRIPT_PATH="${PROJECT_ROOT_DIR}/scripts/set-src-permissions.sh"

# Function to ensure wp-config.php exists
ensure_wp_config() {
  local wp_config_path="src/wp-core/wp-config.php"

  # Check if wp-config.php already exists
  if [ -f "$wp_config_path" ]; then
    echo "✅ wp-config.php already exists"
    return 0
  fi

  # Create wp-config.php using the dedicated script
  if [ -f "scripts/create-wp-config.sh" ]; then
    echo "📝 Creating wp-config.php..."
    ./scripts/create-wp-config.sh
  else
    echo "⚠️  scripts/create-wp-config.sh not found"
    return 1
  fi
}

# Check if SETUP-INFO.md exists
if [ ! -f "${PROJECT_ROOT_DIR}/SETUP-INFO.md" ]; then
  echo "🔴 Error: SETUP-INFO.md not found in '${PROJECT_ROOT_DIR}'."
  echo "   Please run './devenv setup' first to generate the necessary configuration and information file."
  exit 1
fi

# Ensure wp-config.php exists
ensure_wp_config

# Remove default WordPress content, not used here
if [ -d "src/wp-core/wp-content" ]; then
  echo "🗑️ Removing default WordPress content..."
  rm -rf src/wp-core/wp-content
  echo "   Default wp-content directory removed"
fi

echo "🚀 Bringing up Docker services via docker-compose..."

# Change to the project root directory to ensure docker-compose finds its file
cd "${PROJECT_ROOT_DIR}" || exit

# Check if --build flag is passed to force a permissions check
force_permission_check=false
for arg in "$@"; do
  if [[ "$arg" == "--build" ]]; then
    force_permission_check=true
    break
  fi
done

# Resolve a "port is already allocated" conflict: parse the port(s) Docker failed
# to bind from the compose log, find the container(s) bound to each, stop them
# (never this project's own containers), and return 0 so the caller retries.
# Returns 1 when no container holds the port (host process or stale proxy),
# after printing an actionable manual-fix message.
_resolve_port_conflict() {
    local up_log="$1"

    # Parse failing ports from lines like:
    #   "Bind for :::80 failed: port is already allocated"
    #   "Bind for 0.0.0.0:443 failed: ..."
    #   "Bind for [::]:80 failed: ..."
    # Falls back to the stack's declared ports if parsing finds nothing.
    local failed_ports
    failed_ports=$(
        grep -Eo 'Bind for [^[:space:]]+ failed' "$up_log" \
            | sed -E 's/.*:([0-9]+) failed.*/\1/' \
            | sort -u | tr '\n' ' '
    )

    # Always scan the full set of host ports this stack publishes, unioned
    # with any extra ports Docker named in the error. A sibling stack can hold
    # several of our ports at once (e.g. :80 and :1025); freeing them one at a
    # time lets the next conflict surface on the following retry and exhaust
    # it. Resolve every conflict in a single pass instead.
    local stack_ports='80|443|1025|8025'
    local ports_alt="$stack_ports"
    if [ -n "$failed_ports" ]; then
        local extra
        extra=$(echo "$failed_ports" | tr ' ' '\n' | grep -v '^$' | paste -sd '|' -)
        ports_alt="${stack_ports}|${extra}"
        echo -e "\n🔌 Port conflict detected on host port(s): ${failed_ports}"
        echo "   Freeing every foreign container on stack ports (${stack_ports//|/, }) in one pass."
    else
        echo -e "\n🔌 Port conflict detected (could not parse port; scanning stack ports ${stack_ports//|/, })."
    fi

    # Project name to exclude our own containers. Compose v2 names containers
    # "<project>-<service>-N" (hyphen); older v1 used "<project>_<service>_N".
    # Match either separator so we never stop this stack's own containers.
    local project_name
    project_name=$(grep COMPOSE_PROJECT_NAME .env 2>/dev/null | head -1 | cut -d '=' -f 2 | tr -d '[:space:]"'"'")
    if [ -z "$project_name" ]; then
        project_name=$(basename "$PWD")
    fi

    # Find containers (excluding ours) that publish one of the target ports as a
    # host bind. The Ports column looks like "0.0.0.0:80->80/tcp, :::80->80/tcp".
    # Match "<port>->" so a bind like :8080-> is never confused with :80->.
    local matches
    matches=$(
        docker ps --format '{{.ID}}\t{{.Names}}\t{{.Ports}}' \
            | awk -F '\t' -v proj="^${project_name}[-_]" -v ports="(:|[[:space:]])(${ports_alt})->" '
                $2 !~ proj && $3 ~ ports { print $0 }
            '
    )

    if [ -n "$matches" ]; then
        echo "   Stopping the container(s) holding the taken port(s):"
        echo "$matches" | while IFS=$'\t' read -r _ cname cports; do
            echo "   - ${cname} (${cports})"
        done

        local ids
        ids=$(echo "$matches" | awk -F '\t' '{print $1}')
        echo "$ids" | xargs -r docker stop >/dev/null
        echo "   Conflicting container(s) stopped. Restart them manually if you need them."
        return 0
    fi

    # No container owns the port: a host process (apache2/nginx/httpd) or a
    # wedged docker-proxy is holding it. Surface a precise manual fix.
    local first_port
    first_port=$(echo "${failed_ports}" | awk '{print $1}')
    [ -z "$first_port" ] && first_port=80
    echo "   No Docker container is bound to the conflicting port."
    echo "   A host process (apache2, nginx, httpd) or a stale docker-proxy likely holds it. Find and stop it:"
    echo "     sudo ss -ltnp 'sport = :${first_port}'   # show the PID holding port ${first_port}"
    echo "     sudo systemctl stop apache2 nginx        # common culprits"
    echo "     docker system prune -f                   # clear stale docker-proxy state"
    return 1
}

# Bring up Docker services with a bounded retry loop that self-heals port
# and network conflicts. A stack can hit several conflicts at once (e.g. a
# sibling stack holding :80, :443 and :1025); each `docker-compose up` failure
# reveals only the next blocker, so we loop until the stack is up, nothing
# more can be auto-healed, or the attempt cap is reached.
docker_up_with_retry() {
    echo "🚀 Bringing up Docker services via docker-compose..."

    local up_log rc i healed
    local max_attempts=4
    up_log=$(mktemp)

    for (( i=1; i<=max_attempts; i++ )); do
        # CRITICAL: a bare `cmd | tee` reports tee's exit status (always 0),
        # masking a docker-compose failure and making the script falsely print
        # "started successfully". Disable set -e and enable pipefail so $?
        # reflects docker-compose, while still streaming live output.
        set +e
        set -o pipefail
        docker-compose up "$@" 2>&1 | tee "$up_log"
        rc=$?
        set +o pipefail
        set -e

        if [ "$rc" -eq 0 ]; then
            rm -f "$up_log"
            if [ "$i" -eq 1 ]; then
                echo "✅ Docker services started successfully on the first attempt."
            else
                echo "✅ Docker services started successfully (attempt ${i} of ${max_attempts})."
            fi
            return 0
        fi

        # Pick the self-heal that matches THIS failure. Order matters: a port
        # bind failure during network setup is reported as "failed to set up
        # container networking ... Bind for <port> failed", containing both
        # phrases. The port bind is the actionable root cause, so check it
        # first; a genuine missing-network (no port bind) falls through to the
        # network heal.
        healed=0
        if grep -Eiq "port is already allocated|Bind for .* failed" "$up_log" 2>/dev/null; then
            # _resolve_port_conflict stops every foreign container holding a
            # stack port. It returns 1 when a host process (not a container)
            # owns the port, which cannot be auto-fixed.
            if _resolve_port_conflict "$up_log"; then
                healed=1
            else
                rm -f "$up_log"
                echo -e "\n🔴 'docker-compose up' failed; conflicting port is held by a host process, not a container. See the guidance above."
                return 1
            fi
        elif grep -Eiq "failed to set up container networking|network .* not found" "$up_log" 2>/dev/null; then
            # Containers can reference a missing Docker network after daemon
            # resets. Tear the partial stack down and retry.
            echo -e "\n🩹 Detected missing Docker network reference. Healing compose state..."
            docker-compose down --remove-orphans >/dev/null 2>&1 || true
            docker-compose rm -f >/dev/null 2>&1 || true
            healed=1
        fi

        if [ "$healed" -eq 0 ]; then
            rm -f "$up_log"
            echo -e "\n🔴 'docker-compose up' failed for a reason other than a port or network conflict. Check the logs above."
            return 1
        fi

        if [ "$i" -lt "$max_attempts" ]; then
            echo -e "\n🔄 Retrying 'docker-compose up' (attempt $((i + 1)) of ${max_attempts})..."
        fi
    done

    rm -f "$up_log"
    echo -e "\n🔴 'docker-compose up' still failing after ${max_attempts} attempts. Check the logs above."
    return 1
}

# Determine arguments and call the retry function.
if [ $# -eq 0 ]; then
    echo "   No arguments provided, defaulting to detached mode (-d)."
    docker_up_with_retry -d
    up_status=$?
    was_detached_by_default=true
else
    echo "   Passing arguments to docker-compose up: $*"
    docker_up_with_retry "$@"
    up_status=$?
    was_detached_by_default=false
fi

if [ $up_status -ne 0 ]; then
    exit $up_status
fi

# Function to setup SELinux contexts if needed
setup_selinux() {
  # Check if SELinux is available and enforcing
  if ! command -v getenforce >/dev/null 2>&1; then
    return 0 # SELinux not available, skip
  fi

  local selinux_status
  selinux_status=$(getenforce 2>/dev/null || echo "Disabled")

  if [ "$selinux_status" != "Enforcing" ]; then
    return 0 # SELinux not enforcing, skip
  fi

  echo "🔒 SELinux is enforcing. Setting up container file contexts for project..."

  # Set SELinux file context for this project directory
  if sudo semanage fcontext -a -t container_file_t "${PROJECT_ROOT_DIR}(/.*)?"; then
    echo "   SELinux context rule added for ${PROJECT_ROOT_DIR}"
  else
    echo "   SELinux context rule already exists or failed to add"
  fi

  # Apply the context to all files in the project
  if sudo restorecon -Rv "${PROJECT_ROOT_DIR}"; then
    echo "   SELinux contexts applied successfully"
  else
    echo "⚠️  Warning: Failed to apply SELinux contexts"
    return 1
  fi

  return 0
}

# The docker-compose up command has finished.
# Now, conditionally run SELinux setup and permissions script.
PERMISSION_FLAG_FILE="${PROJECT_ROOT_DIR}/.permissions_set"

# We run the script if the flag file doesn't exist (first run) or if --build was passed.
if [ ! -f "${PERMISSION_FLAG_FILE}" ] || [ "$force_permission_check" = true ]; then
  echo ""
  host_os="$(uname -s)"

  if [[ "$host_os" != "Linux" ]]; then
    echo "ℹ️  Non-Linux host detected (${host_os}). Skipping SELinux/Linux permission adjustments."
    touch "${PERMISSION_FLAG_FILE}"
  else
    if [ ! -f "${PERMISSION_FLAG_FILE}" ]; then
      echo "🔐 First start detected. Setting up SELinux and applying host permissions for the ./src directory..."
    else
      echo "🔐 --build flag detected. Re-setting up SELinux and applying host permissions for the ./src directory..."
    fi

    # Setup SELinux contexts if needed
    setup_selinux

    # Fix src directory ownership for container access
    if [ -d "${PROJECT_ROOT_DIR}/src" ]; then
      echo "🔧 Setting proper ownership for ./src directory..."
      if sudo chown -R 1000:1000 "${PROJECT_ROOT_DIR}/src"; then
        echo "   Ownership set to 1000:1000 for ./src"
      else
        echo "⚠️  Warning: Failed to set ownership for ./src directory"
      fi
    fi

    if [ -f "${PERMISSION_SCRIPT_PATH}" ]; then
      if [ ! -x "${PERMISSION_SCRIPT_PATH}" ]; then
        chmod +x "${PERMISSION_SCRIPT_PATH}"
      fi

      # Execute the permission script and create the flag file on success
      if "${PERMISSION_SCRIPT_PATH}"; then
        touch "${PERMISSION_FLAG_FILE}"
        echo "   SELinux setup and permissions applied successfully."
      else
        echo "⚠️ Error: Permission script failed. It will be run again on the next start."
      fi
    else
      echo "⚠️ Error: Permission script not found at ${PERMISSION_SCRIPT_PATH}"
      exit 1
    fi
  fi
else
  echo ""
  echo "✅ Permissions already set. Skipping."
fi

# Ensure wp-config.php exists
ensure_wp_config

# Check if WordPress needs to be installed
if [ -f ".env" ]; then
  # shellcheck disable=SC1091
  source .env
  if ! ./wp core is-installed >/dev/null 2>&1; then
    echo "📦 WordPress not installed. Installing now..."
    ./wp core install \
      --url="${WP_URL}" \
      --title="${WP_TITLE}" \
      --admin_user="${WP_ADMIN_USER}" \
      --admin_password="${WP_ADMIN_PASSWORD}" \
      --admin_email="${WP_ADMIN_EMAIL}" \
      --skip-email

    # Activate plugins and theme
    ./wp plugin activate --all

    # Wait a moment for themes to be properly registered
    echo "⏳ Waiting for themes to be registered..."
    sleep 3

    # Re-check if themes are available
    echo "📋 Available themes:"
    ./wp theme list --status=inactive

    # Check if twentytwentyfive theme exists and activate it, otherwise fallback to a default theme
    if ./wp theme is-installed twentytwentyfive >/dev/null 2>&1; then
      ./wp theme activate twentytwentyfive
    elif ./wp theme is-installed twentytwentyfour >/dev/null 2>&1; then
      echo "⚠️  twentytwentyfive theme not found, falling back to twentytwentyfour"
      ./wp theme activate twentytwentyfour
    elif ./wp theme is-installed twentytwentythree >/dev/null 2>&1; then
      echo "⚠️  twentytwentyfive and twentytwentyfour themes not found, falling back to twentytwentythree"
      ./wp theme activate twentytwentythree
    else
      echo "⚠️  No recent default themes found, checking for any available theme"
      # Get list of available themes and activate the first one
      available_themes=$(./wp theme list --status=inactive --field=name)
      if [ -n "$available_themes" ]; then
        first_theme=$(echo "$available_themes" | head -n 1)
        echo "   Activating theme: $first_theme"
        ./wp theme activate "$first_theme"
      else
        echo "⚠️  No themes available to activate"
      fi
    fi

    echo "✅ WordPress installation completed!"

    # Remove wp-content created by installation to ensure bind mount works
    if [ -d "src/wp-core/wp-content" ]; then
      echo "🗑️ Removing WordPress-created wp-content to enable bind mount..."
      rm -rf src/wp-core/wp-content
      echo "   wp-content directory removed from wp-core to allow bind mount"
    fi

    # Also clean up any stray wp-content in current directory
    if [ -d "wp-content" ] && [ ! -L "wp-content" ]; then
      echo "🗑️ Removing stray wp-content directory created before volume mount..."
      rm -rf wp-content
      echo "   Local wp-content directory removed"
    fi

    # Restart PHP container to ensure bind mount takes effect
    echo "🔄 Restarting PHP container to apply bind mount..."
    docker-compose restart php
    echo "   PHP container restarted"
  fi
fi

echo ""
echo "🎉 Docker environment is up and host permission setup has been processed."

# Determine if services are running in detached mode for the final message
running_detached=false
if [ "$was_detached_by_default" = true ]; then
  running_detached=true
else
  # Check if -d or --detach is in the arguments provided by the user
  for arg in "$@"; do
    if [[ "$arg" == "-d" ]] || [[ "$arg" == "--detach" ]]; then
      running_detached=true
      break
    fi
  done
fi

if [ "$running_detached" = true ]; then
  echo "   Services are running in detached mode."
else
  echo "   Services were started in the foreground. If you stop them (Ctrl+C), permissions are already set for the next run."
fi

echo "   Usage: './devenv start' (defaults to detached mode)."
echo "   You can pass any 'docker-compose up' arguments, e.g., './devenv start --build -d', './devenv start wordpress'."
echo "   If arguments are provided and '-d' or '--detach' is not among them, services will likely start in the foreground (e.g., './devenv start --build')."
echo "   To stop services, run './devenv stop' or 'docker-compose down'."
