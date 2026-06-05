# ⚙️ Environment Variables Configuration Guide

This guide documents the environment variables used to configure the **NousResearch Hermes Agent** container, API gateways, and Telegram bot platforms.

---

## 📂 Variable Scopes (Global vs. Profile)

Hermes supports two scopes for environment configuration:
1. **Global/Container Scope (`.env` in the root)**: Read by Docker Compose to set up container-wide settings (such as user IDs, ports, and default dashboard options).
2. **Profile-Specific Scope (`.env` inside profile folders)**: Loaded by the specific gateway process for each profile (e.g. `data/profiles/urvets-api/.env`). Perfect for separate Telegram tokens, allowed topic IDs, and LLM keys.

---

## 🐳 Docker Container Settings

Configure these in the root `.env` to manage how the Docker container executes.

| Variable | Default | Description |
| :--- | :--- | :--- |
| `HERMES_UID` | `1000` | The host user ID mapped inside the container. Match this to your host user (`$(id -u)`) to avoid permissions issues. |
| `HERMES_GID` | `1000` | The host group ID mapped inside the container. Match this to your host group (`$(id -g)`). |
| `HERMES_DASHBOARD` | `1` | Enables (`1`) or disables (`0`) the administrative web dashboard. |
| `HERMES_DASHBOARD_PORT` | `9119` | The port the web dashboard UI will bind to inside the container. |
| `HERMES_DASHBOARD_INSECURE`| `1` | Disables OAuth requirement for dashboard access. Set to `0` in public deployments. |

---

## 🤖 Telegram Integration Settings

Set these within your profile-specific `.env` files to configure bot routing and permission gates.

| Variable | Example | Description |
| :--- | :--- | :--- |
| `TELEGRAM_BOT_TOKEN` | `6207411...` | The official API token for your bot account obtained from `@BotFather`. |
| `TELEGRAM_ALLOWED_USERS` | `5214495...` | Comma-separated list of numeric Telegram User IDs allowed to query the bot. |
| `TELEGRAM_HOME_CHANNEL` | `-1003956...`| The Telegram Group/Channel Chat ID where the bot operates. |
| `TELEGRAM_HOME_CHANNEL_NAME`| `UrVets-API` | Visual display name for the channel or topic configuration. |
| `TELEGRAM_ALLOWED_TOPICS` | `2` | Comma-separated list of Topic Thread IDs. Restricts the bot to only react/respond inside these topics. |
| `TELEGRAM_HOME_CHANNEL_THREAD_ID`| `2` | Tells the bot which topic thread to use when initializing new chats. |
| `TELEGRAM_CRON_THREAD_ID` | `2` | Directs cron jobs and background reports to print in this topic thread. |

---

## 🔑 LLM Provider API Keys

Set these to provide API credentials for your model processing.

| Variable | Description |
| :--- | :--- |
| `OPENAI_API_KEY` | Credentials for OpenAI models. |
| `ANTHROPIC_API_KEY` | Credentials for Anthropic (Claude) models. |
| `OPENROUTER_API_KEY` | Credentials for OpenRouter model access. |

---

## 🔌 API Server & Integrations

Controls the OpenAI-compatible local API server and developer integrations.

| Variable | Default | Description |
| :--- | :--- | :--- |
| `API_SERVER_ENABLED` | `true` | When true, starts the OpenAI-compatible server at port `8642`. |
| `API_SERVER_KEY` | `sk-...` | Token required in the Authorization header to call the local gateway API. |
| `GITHUB_TOKEN` / `GH_TOKEN`| | Access tokens used by Hermes when executing Git integrations, creating PRs, or fetching issues. |
