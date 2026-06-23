# 🤖 Multi-Instance Discord Gateway Guide

This document describes the architecture and management of running **multiple concurrent Discord Bot instances** inside a single supervised Hermes container.

---

## 🏛️ Architecture Overview

The Hermes Docker container utilizes the **s6-overlay** process supervisor to manage background services. Instead of running a single global gateway, Hermes spawns a separate supervisor service for each active profile:

```mermaid
graph TD
    Container[Hermes Docker Container] --> s6[s6-overlay Supervisor]
    s6 --> GW_Default[gateway-default]
    s6 --> GW_UrVets[gateway-urvets-api]
    s6 --> GW_NestJS[gateway-nestjs-expert]
    
    GW_Default --> Bot_A[Discord Bot A - default]
    GW_UrVets --> Bot_B[Discord Bot B - urvets-api]
    GW_NestJS --> Bot_C[Discord Bot C - nestjs-expert]
```

Each process is completely isolated in its memory space, virtual environment, and configuration directory.

---

## 📂 Configuration Isolation

Each gateway reads its environment configuration exclusively from its profile directory. This prevents environment variable naming collisions:

| Profile Name | Local Config Path | Active Variables |
| :--- | :--- | :--- |
| **default** | `data/.env` | `DISCORD_BOT_TOKEN` (Bot A) |
| **urvets-api** | `data/profiles/urvets-api/.env` | `DISCORD_BOT_TOKEN` (Bot B) |
| **nestjs-expert**| `data/profiles/nestjs-expert/.env`| `DISCORD_BOT_TOKEN` (Bot C) |

---

## 🛡️ Platform Token Locks

To prevent conflicts and double polling (such as two processes connecting to Discord with the same token), Hermes implements a **Platform Lock** system:
* When a gateway starts, it registers a lock on its bot token (`discord-bot-token:<TOKEN_HASH>`).
* Since each profile configured in this multi-instance architecture uses a **unique token**, each process successfully acquires its lock and runs independently.
* If you accidentally reuse the same token across different profiles, the supervisor logs will report a locking conflict, and the second process will fail to run until the conflict is resolved.

---

## 🛠️ Managing Supervisor Services

You can manage the individual gateway instances directly from your host machine via `docker exec`.

### 1. Check Service Status
Check the status of all supervised services, including process IDs (PIDs) and uptime:
```bash
# Check default gateway
docker exec hermes /command/s6-svstat /run/service/gateway-default

# Check urvets-api gateway
docker exec hermes /command/s6-svstat /run/service/gateway-urvets-api
```

### 2. Restart a Specific Bot/Gateway
If you modify a profile's `.env` or configurations, restart only that profile's gateway without affecting the others:
```bash
# Restart default gateway
docker exec hermes /command/s6-svc -t /run/service/gateway-default

# Restart urvets-api gateway
docker exec hermes /command/s6-svc -t /run/service/gateway-urvets-api
```

### 3. View Logs
Each bot instance writes its logs into its own profile workspace:
* **Default**: `data/logs/agent.log`
* **UrVets API**: `data/profiles/urvets-api/logs/agent.log`
* **NestJS Expert**: `data/profiles/nestjs-expert/logs/agent.log`

---

## 🔍 Troubleshooting

### Session or Token Conflicts
> [!WARNING]
> If a bot is not responding or crashes repeatedly:
> * Ensure you did not start the same bot token outside the docker container (e.g. running natively on your host).
> * Check the logs for token lock conflicts. Ensure the bot token is not duplicated between different profiles.
