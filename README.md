# 🚀 Hermes Custom Base Installer

This folder contains the self-contained installer config for building and deploying your customized version of the **NousResearch Hermes Agent**. 

It packages all custom code modifications directly into the Docker image, eliminating the need to mount the codebase via volumes.

---

## ⚙️ NPX Installation

You can install these base installer files into any other project folder using `npx`.

### Option 1: Direct Local Execution
Run `npx` followed by the absolute path of this repository from your target project directory:
```bash
npx /Users/raf/Development/base-hermes install
```

### Option 2: Global Link Execution
Alternatively, you can link the package globally to run it from anywhere:
1. In this directory (`/Users/raf/Development/base-hermes`), run:
   ```bash
   npm link
   ```
2. Navigate to your target project folder and run:
   ```bash
   npx base-hermes install
   ```

### Option 3: Direct Git/GitHub Execution
Once this repository is pushed to GitHub or another git server, you can execute it directly from the remote repository without having it cloned locally:
```bash
npx github:<username>/<repo-name> install
```
or via the full Git URL:
```bash
npx https://github.com/<username>/<repo-name>.git install
```

By default, this will copy the installer files to a local `installer/` directory. If you wish to overwrite existing files, add the `--force` (or `-f`) flag.

---

## 📦 What's Included

The installer copies the following custom code overrides directly into the container:

| Source File | Container Target Path | Description |
| :--- | :--- | :--- |
| `web_server.py` | `/opt/hermes/hermes_cli/web_server.py` | Overrides for the CLI and Web Server |
| `telegram.py` | `/opt/hermes/gateway/platforms/telegram.py` | Custom Telegram Integration logic |
| `gateway_run.py` | `/opt/hermes/gateway/run.py` | Override for the main Gateway runner |
| `scheduler.py` | `/opt/hermes/cron/scheduler.py` | Custom Cron scheduler logic |

---

## 🛠️ Build instructions

To build the self-contained Docker image, run the following command from the **root of the repository**:

```bash
docker build -t hermes-custom:latest installer/
```

---

## 🚀 Deployment Guide

### 1. Configure Environment
Before deploying, copy the example environment file:
```bash
cp installer/.env.example .env
```
Open the `.env` file and specify your keys and preferences (e.g. `API_SERVER_KEY`, LLM provider keys, etc.).

### 2. Configure Telegram (Interactive Setup)
To configure your Telegram bots and topic thread mappings using the interactive Q&A wizard, run:
```bash
./installer/setup-telegram.sh
```
This wizard will ask which profile you are configuring (e.g. `default` or `urvets-api`), prompt you for the bot token, allowed users, and thread IDs, and automatically update the correct profile-specific `.env` file inside your `data/` directory.

### 3. Persistent Data Mount
Although the custom code is baked directly into the image, your sessions, credentials, memories, and databases must persist across container updates. Always mount the `./data` directory.

### 4. Run with Docker CLI
Run the following command to start your custom Hermes Agent container:

```bash
docker run -d \
  --name hermes-custom \
  --restart unless-stopped \
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

> [!TIP]
> Setting `HERMES_UID` and `HERMES_GID` to match your local user ID (`$(id -u)` and `$(id -g)`) guarantees that files written to `./data` by the container remain owned by you on macOS, preventing permissions issues when editing configs locally.

---

## ⚙️ Standalone Docker Compose Setup

A fully configured `docker-compose.yml` is already provided inside the `installer/` directory. This allows you to launch the environment with a single command:

1. **Change directory to `installer/`**:
   ```bash
   cd installer/
   ```
2. **Set up the environment file**:
   ```bash
   cp .env.example .env
   ```
3. **Configure your secrets**:
   Open the `.env` file and set your `API_SERVER_KEY`, LLM provider credentials, and Telegram bot settings.
4. **Launch the stack**:
   ```bash
   docker compose up -d --build
   ```

This will build the custom Docker image, mount the persistent `./data` folder locally under `installer/data/`, load all environment configurations, and start the Hermes gateway and dashboard.

---

## 🤖 Running Multiple Telegram Bots with Group Topics

Hermes supports running **multiple concurrent profiles** (e.g. `default` and `urvets-api`) under the same container. If you want to use a separate Telegram bot for each profile while keeping them in the same group chat, you can segregate their responses using **Telegram Group Topics (Forum Threads)**.

### How it Works
1. Each profile runs its own background gateway process inside the container.
2. Rather than reading the top-level container variables, each profile loads configuration from its profile-specific `.env` file inside the mounted `data` folder:
   - Default Profile: `data/.env`
   - UrVets API Profile: `data/profiles/urvets-api/.env`
   - NestJS Expert Profile: `data/profiles/nestjs-expert/.env`

### Example Configuration

To configure this, set up each profile's `.env` file with its own bot token and restrict it to its designated topic using `TELEGRAM_ALLOWED_TOPICS`.

#### 1. Default Profile (`data/.env`)
```ini
TELEGRAM_BOT_TOKEN=6207411587:AAHH5b2sV...
TELEGRAM_ALLOWED_USERS=5214495119
TELEGRAM_HOME_CHANNEL=-1003956980090
TELEGRAM_HOME_CHANNEL_NAME=General
TELEGRAM_HOME_CHANNEL_THREAD_ID=1
TELEGRAM_CRON_THREAD_ID=1
TELEGRAM_ALLOWED_TOPICS=1
```

#### 2. UrVets API Profile (`data/profiles/urvets-api/.env`)
```ini
TELEGRAM_BOT_TOKEN=8904380117:AAHpzCRz3...
TELEGRAM_ALLOWED_USERS=5214495119
TELEGRAM_HOME_CHANNEL=-1003956980090
TELEGRAM_HOME_CHANNEL_NAME=UrVets-API
TELEGRAM_HOME_CHANNEL_THREAD_ID=2
TELEGRAM_CRON_THREAD_ID=2
TELEGRAM_ALLOWED_TOPICS=2
```

> [!IMPORTANT]
> - **`TELEGRAM_HOME_CHANNEL`**: Both bots must share the same parent Supergroup ID.
> - **`TELEGRAM_ALLOWED_TOPICS`**: Restricts each bot to only listen and respond inside the specified topic thread ID. This prevents Bot A from trying to answer queries sent to Bot B, and vice-versa.
> - **`TELEGRAM_HOME_CHANNEL_THREAD_ID` / `TELEGRAM_CRON_THREAD_ID`**: Ensures that system status reports, cron notifications, and active sessions are correctly routed inside the specified topic thread.

---

## 📖 Comprehensive Guides

For deep-dives into topic routing and multi-bot configurations, refer to the guides included in this installer's `docs/` folder:
* **[Docker Setup & Architecture Guide](docs/docker/docker-hermes-setup.md)**: Details the container architecture, custom script baking, and user permissions mapping.
* **[Environment Variables Guide](docs/config/env-variables-guide.md)**: Reference for global and profile-specific env configurations.
* **[Profile Installation Guide](docs/profile/README.md)**: Details custom profile layouts (SOUL.md, skills.md) and installation scripts.
* **[Setup Steps Checklist](docs/telegram/setup-checklist.md)**: End-to-end chronological checklist from Bot creation to topic mapping.
* **[Profile-to-Topic Mapping Guide](docs/telegram/telegram-topic-routing.md)**: Detailed step-by-step setup to map profiles to specific forum topics.
* **[Multi-Instance Gateway Guide](docs/telegram/telegram-multi-instance.md)**: Deep-dive into process supervision, locking, isolation, and service command utilities.
