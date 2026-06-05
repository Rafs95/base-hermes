# ==============================================================================
# Hermes Custom Base Installer Dockerfile
# ==============================================================================
# This Dockerfile packages the custom code modifications for Hermes into a
# self-contained Docker image.
#
# Build Instruction (run from the repository root directory):
#   docker build -t hermes-custom:latest installer/
#
# Run Instruction (mounts your persistent data, but uses the baked-in code):
#   docker run -d \
#     --name hermes-custom \
#     -p 8642:8642 \
#     -p 9119:9119 \
#     -v "$(pwd)/data:/opt/data" \
#     -e HERMES_UID=$(id -u) \
#     -e HERMES_GID=$(id -g) \
#     -e HERMES_DASHBOARD=1 \
#     -e HERMES_DASHBOARD_HOST=0.0.0.0 \
#     -e HERMES_DASHBOARD_PORT=9119 \
#     -e HERMES_DASHBOARD_INSECURE=1 \
#     -e GATEWAY_HEALTH_URL=http://127.0.0.1:8642 \
#     -e API_SERVER_ENABLED=true \
#     -e API_SERVER_HOST=0.0.0.0 \
#     hermes-custom:latest gateway run
# ==============================================================================

# 1. Base Image
FROM nousresearch/hermes-agent:latest

# 2. System Dependencies
# Install GitHub CLI (gh) for PR & GitHub integrations
RUN apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# 3. Environment Configuration
# Ensure hermes and virtualenv binaries are in the PATH for all shells
RUN echo 'export PATH="/opt/hermes/bin:/opt/hermes/.venv/bin:$PATH"' >> /etc/bash.bashrc \
    && echo 'export PATH="/opt/hermes/bin:/opt/hermes/.venv/bin:$PATH"' >> /etc/profile

# 4. Inject Custom Hermes Code
# Copy the custom modified python scripts into their respective target locations
COPY gateway_run.py /opt/hermes/gateway/run.py
COPY scheduler.py /opt/hermes/cron/scheduler.py
COPY telegram.py /opt/hermes/gateway/platforms/telegram.py
COPY web_server.py /opt/hermes/hermes_cli/web_server.py

# Set the default workdir
WORKDIR /opt/hermes
