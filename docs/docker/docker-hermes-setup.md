# 🐳 Docker Setup and Architecture for Hermes

This guide documents the Docker architecture and setup for the customized **NousResearch Hermes Agent** runner.

---

## 🏛️ Docker Architecture

Hermes runs inside a Docker container based on the official `nousresearch/hermes-agent` image, customized with system packages and Python overrides.

### Directory Structure for Docker
* **`Dockerfile`**: The main blueprint for the custom image. Installs system tools (like `gh` CLI) and bakes the custom Python script overrides (`telegram.py`, `gateway_run.py`, etc.) directly into the image.
* **`data/` (Volume)**: Contains all runtime files, history database (`state.db`), active session keys, profiles, and skills. This folder is mounted externally to prevent data loss when updating the container.
* **`docker-compose.yml`**: Simplifies the orchestration of the gateway and dashboard UI services.

---

## 🛠️ Image Build and Execution Options

### Option A: Standard Compose Run (Recommended)
Ideal for development or production deployment. Runs directly from the root of your project directory using the pre-configured `docker-compose.yml`:
```bash
cp .env.example .env
docker compose up --build -d
```

### Option B: Standalone Docker CLI Run
If you prefer running a single standalone container without using Docker Compose:
```bash
# Build the image from your project root
docker build -t hermes-custom:latest .

# Run the container (mounting only the persistent data folder)
docker run -d \
  --name hermes-custom \
  -p 8642:8642 \
  -p 9119:9119 \
  -v "$(pwd)/data:/opt/data" \
  -e HERMES_UID=$(id -u) \
  -e HERMES_GID=$(id -g) \
  -e HERMES_DASHBOARD=1 \
  -e HERMES_DASHBOARD_HOST=0.0.0.0 \
  -e HERMES_DASHBOARD_PORT=9119 \
  -e HERMES_DASHBOARD_INSECURE=1 \
  -e GATEWAY_HEALTH_URL=http://127.0.0.1:8642 \
  -e API_SERVER_ENABLED=true \
  -e API_SERVER_HOST=0.0.0.0 \
  hermes-custom:latest gateway run
```

---

## 🔒 Permissions & File Ownership (`HERMES_UID`/`HERMES_GID`)

Because Docker runs inside a Linux environment, any files created by the container (e.g. database updates, new logs, downloaded assets) will be owned by the user running inside the container by default.

To prevent permission denial errors when reading or editing these files from macOS:
1. Always map the environment variables `HERMES_UID` and `HERMES_GID`.
2. The `docker-compose.yml` reads these from the local `.env` file.
3. Automatically configure them to match your macOS user account using:
   ```bash
   sed -i '' "s/HERMES_UID=1000/HERMES_UID=$(id -u)/" .env
   sed -i '' "s/HERMES_GID=1000/HERMES_GID=$(id -g)/" .env
   ```
