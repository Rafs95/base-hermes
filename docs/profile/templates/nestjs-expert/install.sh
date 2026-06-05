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

# 1. Validation & Container Detection
CONTAINER_NAME=""
if docker ps --format '{{.Names}}' | grep -q '^hermes$'; then
  CONTAINER_NAME="hermes"
elif docker ps --format '{{.Names}}' | grep -q '^hermes-custom$'; then
  CONTAINER_NAME="hermes-custom"
fi

if [ -z "$CONTAINER_NAME" ]; then
  echo "❌ Error: The 'hermes' or 'hermes-custom' docker container is not running."
  echo "Please start the services first with: docker compose up -d"
  exit 1
fi

echo "ℹ️ Using running docker container: $CONTAINER_NAME"

# 2. Stage files
echo "📦 Staging profile files to the container volume..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy files
cp -r "$PROFILE_SRC/"* "$STAGING_DIR/"
if [ -d "$PROFILE_SRC/.agents" ]; then
  cp -r "$PROFILE_SRC/.agents" "$STAGING_DIR/"
fi

# 3. Install profile in container
echo "⚙️ Registering profile in Hermes..."
docker exec -i "$CONTAINER_NAME" hermes profile install "/opt/data/tmp_${PROFILE_NAME}_dist" --name "$PROFILE_NAME" --force -y

# 4. Clean up staging
echo "🧹 Cleaning up temporary staging directory..."
rm -rf "$STAGING_DIR"

# 5. Install skills in container
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
    # Execute the command inside the profile folder in the container
    docker exec -w "/opt/data/profiles/$PROFILE_NAME" "$CONTAINER_NAME" $cmd
  done < "$SKILLS_FILE"
  
  # Register skills with the Hermes profile loader
  echo "Registering skills with the Hermes profile loader..."
  docker exec -i "$CONTAINER_NAME" find /opt/data/profiles/$PROFILE_NAME/.agents/skills/ -mindepth 1 -maxdepth 1 -type d -exec cp -rf {} /opt/data/profiles/$PROFILE_NAME/skills/ \;
else
  echo "⚠️ Warning: skills.md / SKILLS.json not found, skipping skill installations."
fi

echo "======================================================================"
echo "✅ Profile '$PROFILE_NAME' installed successfully!"
echo "======================================================================"
echo "To switch to this profile in the CLI, run:"
echo "  docker exec -it $CONTAINER_NAME hermes profile use $PROFILE_NAME"
echo "======================================================================"
