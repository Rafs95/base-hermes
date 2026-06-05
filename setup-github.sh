#!/usr/bin/env bash
# ==============================================================================
# Interactive GitHub Setup Wizard for Hermes
# ==============================================================================
set -euo pipefail

# Helper: Colors and styled messages
echo_title() {
  echo -e "\n======================================================================"
  echo -e "🐙 \033[1;36m$1\033[0m"
  echo -e "======================================================================\n"
}

echo_success() {
  echo -e "✅ \033[1;32m$1\033[0m"
}

echo_warning() {
  echo -e "⚠️ \033[1;33m$1\033[0m"
}

echo_error() {
  echo -e "❌ \033[1;31m$1\033[0m"
}

is_container_running() {
  docker inspect -f '{{.State.Running}}' hermes-custom 2>/dev/null | grep -q "true"
}

# Resolve Workspace Root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == *"/installer" ]]; then
  WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  WORKSPACE_ROOT="$SCRIPT_DIR"
fi

echo_title "Hermes GitHub & Git Setup Wizard"

# 1. Ask for Data Directory Location
DATA_DIR="$WORKSPACE_ROOT/data"
if [ ! -d "$DATA_DIR" ] && [ -d "$SCRIPT_DIR/data" ]; then
  DATA_DIR="$SCRIPT_DIR/data"
fi

if [ -d "$DATA_DIR" ]; then
  echo "Found data directory at: $DATA_DIR"
else
  echo_warning "Could not locate data directory automatically."
  read -r -p "Enter path to your Hermes 'data' folder (e.g., ./data): " custom_data_dir
  DATA_DIR="$(cd "$custom_data_dir" && pwd)"
fi

# 2. Ask for Profile Name
read -r -p "Enter Hermes profile name to configure (press Enter for 'default'): " profile_name
profile_name="${profile_name:-default}"

# Resolve target .env file path
if [ "$profile_name" = "default" ]; then
  ENV_FILE="$DATA_DIR/.env"
else
  ENV_FILE="$DATA_DIR/profiles/$profile_name/.env"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo_warning "Profile environment file not found at: $ENV_FILE"
  read -r -p "Would you like to initialize a new .env file here? [Y/n]: " init_env
  init_env="${init_env:-y}"
  if [[ "$init_env" =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$ENV_FILE")"
    touch "$ENV_FILE"
    echo_success "Initialized new environment file."
  else
    echo "Aborting."
    exit 1
  fi
fi

# 3. Prompt for Git Account Details
echo ""
echo "--- 1. Git Identity Setup ---"
read -r -p "Enter your Git user.name (e.g., John Doe): " git_username
read -r -p "Enter your Git user.email (e.g., john@example.com): " git_email

# 4. Prompt for Personal Access Token (PAT)
echo ""
echo "--- 2. GitHub Token Setup ---"
echo "To interact with GitHub API (PRs, issues, skill search), you need a PAT."
echo "You can create one at: https://github.com/settings/tokens (Fine-grained recommended)"
echo -n "Enter GitHub Personal Access Token (input will be hidden): "
read -r -s github_token
echo ""

if [ -z "$github_token" ]; then
  echo_error "GitHub token cannot be empty."
  exit 1
fi

# 5. Update Env File variables
update_env_var() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    local escaped_val=$(echo "$val" | sed 's/[&/\]/\\&/g')
    sed -i.bak "s|^${key}=.*|${key}=${escaped_val}|" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
  else
    echo "${key}=${val}" >> "$ENV_FILE"
  fi
}

echo ""
echo "Updating environment configuration..."
update_env_var "GITHUB_TOKEN" "$github_token"
update_env_var "GH_TOKEN" "$github_token"
# Pin GH_CONFIG_DIR so gh works even when HOME is redirected to a named profile dir
update_env_var "GH_CONFIG_DIR" "$DATA_DIR/.config/gh"
echo_success "Saved GITHUB_TOKEN, GH_TOKEN, and GH_CONFIG_DIR to $ENV_FILE."

# 6. Set Git config & gh Auth inside the running container if available
CONTAINER_NAME="hermes-custom"
if is_container_running; then
  echo ""
  echo "Applying Git identity inside running container '$CONTAINER_NAME'..."
  docker exec -u hermes "$CONTAINER_NAME" git config --global user.name "$git_username"
  docker exec -u hermes "$CONTAINER_NAME" git config --global user.email "$git_email"
  echo_success "Configured Git user.name and user.email."

  echo "Authenticating GitHub CLI (gh) in the container..."
  if echo "$github_token" | docker exec -i -u hermes "$CONTAINER_NAME" gh auth login --with-token; then
    echo_success "GitHub CLI authenticated successfully."
  else
    echo_warning "Failed to run 'gh auth login' inside the container."
  fi

  # Fix: named profiles run with HOME=<profile_dir>, so gh looks for config there.
  # Symlink .config/gh inside the profile dir to the shared config location.
  if [ "$profile_name" != "default" ]; then
    PROFILE_DIR="$(docker exec -u hermes "$CONTAINER_NAME" sh -c 'echo $HERMES_HOME' 2>/dev/null)"
    PROFILE_DIR="/opt/data/profiles/$profile_name"
    echo "Symlinking gh config into profile '$profile_name' so it works when HOME is set to the profile dir..."
    docker exec -u hermes "$CONTAINER_NAME" bash -c "\
      mkdir -p \"$PROFILE_DIR/.config\" && \
      ln -sfn /opt/data/.config/gh \"$PROFILE_DIR/.config/gh\" && \
      echo 'Symlink: $PROFILE_DIR/.config/gh -> /opt/data/.config/gh'"
    echo_success "gh config symlinked for profile '$profile_name'."
  fi
else
  echo ""
  echo_warning "Container '$CONTAINER_NAME' is not running."
  echo "Identity configuration and 'gh' CLI authentication will apply once the container starts."
  echo "Make sure to run: git config --global user.name \"$git_username\" and email inside the container."
fi

# 7. Configure SSH keys
echo ""
echo "--- 3. SSH Configuration ---"
echo "Choose an SSH option for Git cloning/pushing:"
echo "  1) Generate a new SSH key pair (Recommended)"
echo "  2) Import an existing SSH private key from your host"
echo "  3) Skip SSH configuration"
read -r -p "Select choice [1-3, default 1]: " ssh_choice
ssh_choice="${ssh_choice:-1}"

SSH_DIR="$DATA_DIR/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [ "$ssh_choice" = "1" ]; then
  KEY_FILE="$SSH_DIR/id_ed25519"
  PUB_FILE="${KEY_FILE}.pub"

  if [ -f "$KEY_FILE" ]; then
    echo_warning "An SSH key already exists at $KEY_FILE."
    read -r -p "Overwrite existing key? [y/N]: " overwrite_ssh
    overwrite_ssh="${overwrite_ssh:-n}"
  else
    overwrite_ssh="y"
  fi

  if [[ "$overwrite_ssh" =~ ^[Yy]$ ]]; then
    echo "Generating new Ed25519 SSH key pair..."
    rm -f "$KEY_FILE" "${KEY_FILE}.pub"
    ssh-keygen -t ed25519 -C "$git_email" -f "$KEY_FILE" -N ""
    chmod 600 "$KEY_FILE"
    chmod 644 "$PUB_FILE"
    echo_success "New SSH key pair generated successfully."
  fi

  echo ""
  echo "======================================================================"
  echo "🔑 Add this SSH Public Key to your GitHub settings (https://github.com/settings/keys):"
  echo "======================================================================"
  cat "$PUB_FILE"
  echo "======================================================================"
  echo ""

elif [ "$ssh_choice" = "2" ]; then
  read -r -p "Enter path to your host private key (e.g. ~/.ssh/id_ed25519): " host_key_path
  # Resolve ~ to home directory in bash
  host_key_path="${host_key_path/#\~/$HOME}"

  if [ -f "$host_key_path" ]; then
    echo "Copying private key to Hermes data directory..."
    cp "$host_key_path" "$SSH_DIR/id_ed25519"
    chmod 600 "$SSH_DIR/id_ed25519"
    
    # Try copying the public key if it exists
    if [ -f "${host_key_path}.pub" ]; then
      cp "${host_key_path}.pub" "$SSH_DIR/id_ed25519.pub"
      chmod 644 "$SSH_DIR/id_ed25519.pub"
    fi
    echo_success "SSH private key imported successfully."
  else
    echo_error "Source key file not found at: $host_key_path. Skipping SSH import."
  fi
else
  echo "Skipping SSH configuration."
fi

# Add github.com to known_hosts to prevent interactive prompt on first connection
if [ "$ssh_choice" = "1" ] || [ "$ssh_choice" = "2" ]; then
  echo "Adding github.com to known_hosts..."
  ssh-keyscan -t ed25519 github.com >> "$SSH_DIR/known_hosts" 2>/dev/null || true
  # Deduplicate known_hosts lines
  if [ -f "$SSH_DIR/known_hosts" ]; then
    sort -u "$SSH_DIR/known_hosts" -o "$SSH_DIR/known_hosts"
    chmod 644 "$SSH_DIR/known_hosts"
  fi
  echo_success "github.com registered in known_hosts."
fi

echo_title "Setup Completed Successfully!"
echo "Profile: $profile_name"
echo "Git User: $git_username <$git_email>"
echo ""
echo "Note: If you generated a new SSH key, verify it is added to GitHub before cloning via SSH."
echo "======================================================================\n"
