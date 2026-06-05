# 🗺️ Profile-to-Topic Mapping Guide for Telegram

This guide explains how to configure a **NousResearch Hermes Agent** profile to map to a specific Telegram group topic (Forum Thread). This is ideal for teams or developers who want separate profiles (e.g. `urvets-api`, `nestjs-expert`, or `default`) to live in the same Telegram group chat but communicate exclusively within their designated topics.

---

## 🔍 How Topic-Based Routing Works

In a Telegram group with **Topics** (Forum Mode) enabled:
* Every topic has a unique numeric ID (the `message_thread_id`).
* The **General** topic typically defaults to ID `1` or `None`.
* When a message is sent in a topic, the Telegram Bot API receives the `message_thread_id` of that topic.
* By configuring `TELEGRAM_ALLOWED_TOPICS`, you restrict a specific Hermes profile process to only listen and respond to messages matching that thread ID.

---

## 🛠️ Step-by-Step Setup

### 1. Identify Your Telegram Chat and Topic ID

1. Open your Telegram group.
2. If Topics/Forum Mode is not enabled, go to **Group Info** → **Edit** → **Topics** and enable it.
3. Create a topic (e.g., "UrVets API").
4. **Get the Topic ID (Thread ID)**:
   * **Method A (Web / Desktop)**: Right-click on the topic link and select "Copy Link". The URL will look like `https://t.me/c/123456789/2`. The number at the end (`2`) is the **Topic Thread ID**.
   * **Method B (Via Bot Diagnostics)**: Mention your bot in the topic. Check the logs (`data/profiles/<profile-name>/logs/agent.log`) to see the incoming `message_thread_id`.

---

### 2. Locate Your Profile Config File

Hermes maintains a separated environment file for each profile under the `data/` folder:
* **Default profile**: `data/.env`
* **Custom profiles**: `data/profiles/<profile-name>/.env` (e.g., `data/profiles/urvets-api/.env`)

---

### 3. Update the Profile's `.env` File

Add or edit the following variables in the profile's `.env` file to route communications into the designated topic:

```ini
# The parent Supergroup Chat ID
TELEGRAM_HOME_CHANNEL=-1003956980090
TELEGRAM_HOME_CHANNEL_NAME=UrVets-API

# The designated topic ID for this profile's outputs/cron triggers
TELEGRAM_HOME_CHANNEL_THREAD_ID=2
TELEGRAM_CRON_THREAD_ID=2

# Gate the bot so it ONLY reads and replies inside this topic ID
# (Crucial to prevent this bot profile from replying to chats in other topics)
TELEGRAM_ALLOWED_TOPICS=2
```

---

## 🛡️ Security & Behavior Isolation

> [!IMPORTANT]
> When `TELEGRAM_ALLOWED_TOPICS` is set:
> * The bot will **silently ignore** any messages or mentions sent in other topics.
> * This enables multiple bots to share the same parent Telegram group without cross-talk or double-replying.
> * Slash commands (e.g. `/goal`, `/help`) will also be ignored unless triggered in the allowed topic.

---

## 🧪 Verification

1. Start or restart your gateway:
   ```bash
   docker exec hermes /command/s6-svc -t /run/service/gateway-<profile-name>
   ```
2. Send a message or ask a question in the designated topic:
   * **Example**: `@your_bot hello`
   * The bot should respond directly in that topic thread.
3. Attempt to mention the same bot in a different topic (e.g., General):
   * The bot should remain silent.
