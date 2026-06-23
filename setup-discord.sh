#!/usr/bin/env bash
# ==============================================================================
# Interactive Discord Setup Wizard for Hermes
# ==============================================================================
set -euo pipefail

# Helper: Print styled messages
echo_title() {
  echo -e "\n======================================================================"
  echo -e "🤖 $1"
  echo -e "======================================================================\n"
}

echo_success() {
  echo -e "✅ $1"
}

echo_warning() {
  echo -e "⚠️ $1"
}

# Resolve Workspace Root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == *"/installer" ]]; then
  WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  WORKSPACE_ROOT="$SCRIPT_DIR"
fi

echo_title "Hermes Discord Configuration Wizard"

# 1. Ask for Data Directory Location
DATA_DIR="$WORKSPACE_ROOT/data"
if [ ! -d "$DATA_DIR" ] && [ -d "$SCRIPT_DIR/data" ]; then
  DATA_DIR="$SCRIPT_DIR/data"
fi

echo "Detecting data directory..."
if [ -d "$DATA_DIR" ]; then
  echo "Found data directory at: $DATA_DIR"
else
  echo_warning "Could not locate data directory automatically."
  read -r -p "Enter path to your Hermes 'data' folder (e.g., ./data): " custom_data_dir
  DATA_DIR="$(cd "$custom_data_dir" && pwd)"
fi

# 2. Ask for Profile Name
read -r -p "Enter Hermes profile name for this Bot (press Enter for 'default'): " profile_name
profile_name="${profile_name:-default}"

# Resolve target .env file path
if [ "$profile_name" = "default" ]; then
  ENV_FILE="$DATA_DIR/.env"
  PROFILE_HOME_DIR="$DATA_DIR"
else
  ENV_FILE="$DATA_DIR/profiles/$profile_name/.env"
  PROFILE_HOME_DIR="$DATA_DIR/profiles/$profile_name"
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

# 3. Interactive Q&A for Discord Configuration
echo ""
read -r -p "1. Enter Discord Bot Token: " bot_token
read -r -p "2. Enter Allowed Discord User ID(s) (comma-separated list, leave empty to allow all): " allowed_users
read -r -p "3. Enter Discord Home Channel ID (where the bot sends notifications): " group_id
read -r -p "4. Enter display name for this channel (e.g., UrVets-API): " channel_name
read -r -p "5. Enter Discord Home Channel Thread ID (optional, press Enter to skip): " thread_id
read -r -p "6. Enter Discord Reply Mode (first/all/off, press Enter for 'first'): " reply_mode
reply_mode="${reply_mode:-first}"
read -r -p "7. Enter API Server Port for this profile (press Enter for default 8642): " api_port
api_port="${api_port:-8642}"

# Determine allow all users based on input
allow_all="false"
if [ -z "$allowed_users" ]; then
  allow_all="true"
fi

# 4. Update or Append variables in the .env file
update_env_var() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    # Escape special characters for sed
    local escaped_val=$(echo "$val" | sed 's/[&/\]/\\&/g')
    sed -i.bak "s|^${key}=.*|${key}=${escaped_val}|" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
  else
    echo "${key}=${val}" >> "$ENV_FILE"
  fi
}

echo ""
echo "✍️ Writing Discord configuration to $ENV_FILE..."

update_env_var "DISCORD_BOT_TOKEN" "$bot_token"
update_env_var "DISCORD_ALLOWED_USERS" "$allowed_users"
update_env_var "DISCORD_ALLOW_ALL_USERS" "$allow_all"
update_env_var "DISCORD_HOME_CHANNEL" "$group_id"
update_env_var "DISCORD_HOME_CHANNEL_NAME" "$channel_name"
update_env_var "DISCORD_HOME_CHANNEL_THREAD_ID" "$thread_id"
update_env_var "DISCORD_REPLY_TO_MODE" "$reply_mode"
update_env_var "API_SERVER_PORT" "$api_port"

# Detect container name for service registration
CONTAINER_NAME=""
if docker ps --format '{{.Names}}' | grep -q '^hermes-custom$'; then
  CONTAINER_NAME="hermes-custom"
elif docker ps --format '{{.Names}}' | grep -q '^hermes$'; then
  CONTAINER_NAME="hermes"
fi

echo_success "Discord configuration updated successfully for profile '$profile_name'!"

if [ -n "$CONTAINER_NAME" ]; then
  echo ""
  echo "🔄 Registering supervised gateway-$profile_name service inside container '$CONTAINER_NAME'..."
  # Reconcile s6 services (generates the service folder for the profile if it doesn't exist)
  docker exec -i "$CONTAINER_NAME" python3 -m hermes_cli.container_boot
  docker exec -i "$CONTAINER_NAME" /command/s6-svscanctl -a /run/service

  # Give s6-svscan a moment to spawn the supervisor and open control FIFOs
  sleep 2

  echo "🚀 Starting/Restarting gateway-$profile_name service..."
  # Check status, restart if running, start if not
  if docker exec -i "$CONTAINER_NAME" /command/s6-svstat "/run/service/gateway-$profile_name" 2>/dev/null | grep -q -E "up|starting"; then
    docker exec -i "$CONTAINER_NAME" /command/s6-svc -t "/run/service/gateway-$profile_name"
    echo_success "Gateway service 'gateway-$profile_name' restarted successfully!"
  else
    docker exec -i "$CONTAINER_NAME" /command/s6-svc -u "/run/service/gateway-$profile_name"
    echo_success "Gateway service 'gateway-$profile_name' started successfully!"
  fi

  echo ""
  echo "To check the status of your gateway service, use:"
  echo "  docker exec $CONTAINER_NAME /command/s6-svstat /run/service/gateway-$profile_name"
  echo "To view service logs, check:"
  if [ "$profile_name" = "default" ]; then
    echo "  tail -f data/logs/agent.log"
  else
    echo "  tail -f data/profiles/$profile_name/logs/agent.log"
  fi
else
  # Check if we are running natively on Ubuntu LTS (or standard systemd system)
  if [ -f /etc/os-release ] && grep -q -i "ubuntu" /etc/os-release; then
    echo ""
    echo "🐧 Ubuntu LTS system detected natively (without Docker running)."
    read -r -p "Would you like to automatically configure and start this bot as a native systemd service? (requires sudo) [y/N]: " register_systemd
    register_systemd="${register_systemd:-n}"

    if [[ "$register_systemd" =~ ^[Yy]$ ]]; then
      SERVICE_NAME="hermes-gateway-$profile_name"
      SERVICE_FILE_TEMP="/tmp/$SERVICE_NAME.service"

      # Detect Python interpreter path
      PYTHON_PATH="$WORKSPACE_ROOT/.venv/bin/python3"
      if [ ! -f "$PYTHON_PATH" ]; then
        PYTHON_PATH="$(which python3)"
      fi

      # Detect hermes launcher binary/script
      HERMES_EXEC="$WORKSPACE_ROOT/.venv/bin/hermes"
      if [ ! -f "$HERMES_EXEC" ]; then
        HERMES_EXEC="$WORKSPACE_ROOT/bin/hermes"
      fi

      if [ ! -f "$HERMES_EXEC" ]; then
        # Fallback to run.py directly if the hermes binary wrapper is missing
        EXEC_COMMAND="$PYTHON_PATH $WORKSPACE_ROOT/gateway_run.py"
      else
        EXEC_COMMAND="$HERMES_EXEC -p $profile_name gateway run"
      fi

      cat <<EOF > "$SERVICE_FILE_TEMP"
[Unit]
Description=Hermes Gateway Service - $profile_name
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKSPACE_ROOT
Environment=HERMES_HOME=$PROFILE_HOME_DIR
ExecStart=$EXEC_COMMAND
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

      echo "Installing systemd service unit file..."
      sudo cp "$SERVICE_FILE_TEMP" "/etc/systemd/system/$SERVICE_NAME.service"
      rm -f "$SERVICE_FILE_TEMP"

      echo "Reloading systemd daemon..."
      sudo systemctl daemon-reload

      echo "Enabling service to start on boot..."
      sudo systemctl enable "$SERVICE_NAME.service"

      echo "Starting service..."
      sudo systemctl restart "$SERVICE_NAME.service"

      echo_success "Systemd service '$SERVICE_NAME' registered and started successfully!"
      echo ""
      echo "Commands to manage your native service:"
      echo "  Check Status:  sudo systemctl status $SERVICE_NAME"
      echo "  View Logs:    sudo journalctl -u $SERVICE_NAME -f"
      echo "  Restart Bot:   sudo systemctl restart $SERVICE_NAME"
      echo "  Stop Bot:      sudo systemctl stop $SERVICE_NAME"
    else
      echo "Skipped native systemd service configuration."
    fi
  else
    echo ""
    echo_warning "Docker container is not running, and native Ubuntu systemd environment not detected."
    echo "Please start the docker container, or manually configure systemd if running on a non-Ubuntu systemd system."
  fi
fi
echo -e "======================================================================\n"
