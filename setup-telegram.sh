#!/usr/bin/env bash
# ==============================================================================
# Interactive Telegram Setup Wizard for Hermes
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

echo_title "Hermes Telegram Configuration Wizard"

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

# 3. Interactive Q&A for Telegram Configuration
echo ""
read -r -p "1. Enter Telegram Bot Token (from @BotFather): " bot_token
read -r -p "2. Enter Allowed Telegram User ID(s) (comma-separated list): " allowed_users
read -r -p "3. Enter Telegram Group Chat ID (e.g., -100xxxxxxxxxx): " group_id
read -r -p "4. Enter display name for this channel/topic (e.g., UrVets-API): " channel_name
read -r -p "5. Enter API Server Port for this profile (press Enter for default 8642): " api_port
api_port="${api_port:-8642}"

# Forum Topics Configuration
read -r -p "6. Does this Telegram group use Topics/Forum threads? [y/N]: " use_topics
use_topics="${use_topics:-n}"

thread_id=""
allowed_topics=""

if [[ "$use_topics" =~ ^[Yy]$ ]]; then
  read -r -p "   -> Enter Topic Thread ID for this profile (e.g., 1, 2, 3): " thread_id
  read -r -p "   -> Restrict bot to ONLY listen & reply in this topic ID? [Y/n]: " restrict_topic
  restrict_topic="${restrict_topic:-y}"
  if [[ "$restrict_topic" =~ ^[Yy]$ ]]; then
    allowed_topics="$thread_id"
  fi
fi

# 4. Update or Append variables in the .env file
update_env_var() {
  local key="$1"
  local val="$2"
  if grep -q "^${key}=" "$ENV_FILE"; then
    # Escape special characters for sed
    local escaped_val=$(echo "$val" | sed 's/[&/\]/\\&/g')
    # Use different separator to avoid collision with bot tokens containing colons
    sed -i.bak "s|^${key}=.*|${key}=${escaped_val}|" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
  else
    echo "${key}=${val}" >> "$ENV_FILE"
  fi
}

echo ""
echo "✍️ Writing Telegram configuration to $ENV_FILE..."

update_env_var "TELEGRAM_BOT_TOKEN" "$bot_token"
update_env_var "TELEGRAM_ALLOWED_USERS" "$allowed_users"
update_env_var "TELEGRAM_HOME_CHANNEL" "$group_id"
update_env_var "TELEGRAM_HOME_CHANNEL_NAME" "$channel_name"
update_env_var "TELEGRAM_HOME_CHANNEL_THREAD_ID" "$thread_id"
update_env_var "TELEGRAM_CRON_THREAD_ID" "$thread_id"
update_env_var "TELEGRAM_ALLOWED_TOPICS" "$allowed_topics"
update_env_var "API_SERVER_PORT" "$api_port"

# Detect container name for display suggestion
CONTAINER_NAME=""
if docker ps --format '{{.Names}}' | grep -q '^hermes-custom$'; then
  CONTAINER_NAME="hermes-custom"
elif docker ps --format '{{.Names}}' | grep -q '^hermes$'; then
  CONTAINER_NAME="hermes"
fi

echo_success "Telegram configuration updated successfully for profile '$profile_name'!"
echo "Please restart your gateway service to apply the new settings:"
if [ -n "$CONTAINER_NAME" ]; then
  if [ "$profile_name" = "default" ]; then
    echo "  docker exec $CONTAINER_NAME /command/s6-svc -t /run/service/gateway-default"
  else
    echo "  docker exec $CONTAINER_NAME /command/s6-svc -t /run/service/gateway-$profile_name"
  fi
else
  echo "  hermes -p $profile_name gateway restart"
fi
echo -e "======================================================================\n"
