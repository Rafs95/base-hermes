#!/usr/bin/env bash
# ==============================================================================
# Installer for Hermes nestjs-expert Profile
# ==============================================================================
set -euo pipefail

PROFILE_NAME="nestjs-expert"

# Resolve directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Check if run from workspace root or inside the templates folder
if [[ "$SCRIPT_DIR" == *"/docs/profile/templates/nestjs-expert" ]]; then
  WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../../../" && pwd)"
  PROFILE_SRC="$SCRIPT_DIR"
else
  WORKSPACE_ROOT="$SCRIPT_DIR"
  PROFILE_SRC="$WORKSPACE_ROOT/docs/profile/templates/$PROFILE_NAME"
fi

DATA_DIR="$WORKSPACE_ROOT/data"
STAGING_DIR="$DATA_DIR/tmp_${PROFILE_NAME}_dist"

echo "======================================================================"
echo "🚀 Installing Hermes Profile: $PROFILE_NAME"
echo "======================================================================"
echo "Workspace Root: $WORKSPACE_ROOT"
echo "Profile Source: $PROFILE_SRC"
echo "======================================================================"

# 1. Validation & Container/Native Detection
CONTAINER_NAME=""
if docker ps --format '{{.Names}}' | grep -q '^hermes$'; then
  CONTAINER_NAME="hermes"
elif docker ps --format '{{.Names}}' | grep -q '^hermes-custom$'; then
  CONTAINER_NAME="hermes-custom"
fi

IS_NATIVE=false
if [ -z "$CONTAINER_NAME" ]; then
  # No running docker container, check if we are on Ubuntu LTS and have hermes CLI available
  if [ -f /etc/os-release ] && grep -q -i "ubuntu" /etc/os-release; then
    IS_NATIVE=true
    echo "ℹ️ Docker container not running. Ubuntu LTS system detected, proceeding with native installation..."
  else
    echo "❌ Error: The 'hermes' or 'hermes-custom' docker container is not running."
    echo "Please start the services first with: docker compose up -d"
    echo "If you are running natively on Ubuntu LTS, make sure you run this in an environment where the 'hermes' CLI is available."
    exit 1
  fi
fi

if [ "$IS_NATIVE" = "false" ]; then
  echo "ℹ️ Using running docker container: $CONTAINER_NAME"

  # 2. Stage files (Docker)
  echo "📦 Staging profile files to the container volume..."
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR"
  cp -r "$PROFILE_SRC/"* "$STAGING_DIR/"
  if [ -d "$PROFILE_SRC/.agents" ]; then
    cp -r "$PROFILE_SRC/.agents" "$STAGING_DIR/"
  fi

  # 3. Install profile in container (Docker)
  echo "⚙️ Registering profile in Hermes..."
  docker exec -i "$CONTAINER_NAME" hermes profile install "/opt/data/tmp_${PROFILE_NAME}_dist" --name "$PROFILE_NAME" --force -y

  # Opt out of default bundled skills so only the custom profile skills are installed (Docker)
  echo "🚫 Opting out of default bundled skills..."
  docker exec -i "$CONTAINER_NAME" hermes -p "$PROFILE_NAME" skills opt-out --remove -y

  # 4. Clean up staging (Docker)
  echo "🧹 Cleaning up temporary staging directory..."
  rm -rf "$STAGING_DIR"
else
  # Native Ubuntu LTS Installation
  echo "⚙️ Registering profile in native Hermes..."
  if ! command -v hermes &>/dev/null; then
    if [ -f "$WORKSPACE_ROOT/.venv/bin/hermes" ]; then
      export PATH="$WORKSPACE_ROOT/.venv/bin:$PATH"
    fi
  fi
  
  if ! command -v hermes &>/dev/null; then
    echo "❌ Error: 'hermes' CLI command not found. Please activate your virtual environment first."
    exit 1
  fi

  hermes profile install "$PROFILE_SRC" --name "$PROFILE_NAME" --force -y
  
  echo "🚫 Opting out of default bundled skills natively..."
  hermes -p "$PROFILE_NAME" skills opt-out --remove -y
fi

# 5. Install skills
SKILLS_FILE="$PROFILE_SRC/skills.md"
if [ ! -f "$SKILLS_FILE" ] && [ -f "$PROFILE_SRC/SKILLS.json" ]; then
  SKILLS_FILE="$PROFILE_SRC/SKILLS.json"
fi

if [ -f "$SKILLS_FILE" ]; then
  echo "🛠️ Installing skills from $(basename "$SKILLS_FILE") into profile..."
  while read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Ensure command has -y flag
    if [[ "$line" != *"-y"* ]]; then
      cmd="$line -y"
    else
      cmd="$line"
    fi
    
    echo "Running: $cmd"
    if [ "$IS_NATIVE" = "false" ]; then
      # Execute inside container
      docker exec -w "/opt/data/profiles/$PROFILE_NAME" "$CONTAINER_NAME" $cmd
    else
      # Execute natively
      (cd "$DATA_DIR/profiles/$PROFILE_NAME" && eval "$cmd")
    fi
  done < "$SKILLS_FILE"
  
  # Register skills with the Hermes profile loader
  echo "Registering skills with the Hermes profile loader..."
  if [ "$IS_NATIVE" = "false" ]; then
    docker exec -i "$CONTAINER_NAME" find /opt/data/profiles/$PROFILE_NAME/.agents/skills/ -mindepth 1 -maxdepth 1 -type d -exec cp -rf {} /opt/data/profiles/$PROFILE_NAME/skills/ \;
  else
    mkdir -p "$DATA_DIR/profiles/$PROFILE_NAME/skills/"
    find "$DATA_DIR/profiles/$PROFILE_NAME/.agents/skills/" -mindepth 1 -maxdepth 1 -type d -exec cp -rf {} "$DATA_DIR/profiles/$PROFILE_NAME/skills/" \; 2>/dev/null || true
  fi
else
  echo "⚠️ Warning: skills.md / SKILLS.json not found, skipping skill installations."
fi

echo "======================================================================"
echo "✅ Profile '$PROFILE_NAME' files and skills installed successfully!"
echo "======================================================================"
echo "Next step: Run setup-telegram.sh to configure the bot token and start the gateway."
echo "======================================================================"

