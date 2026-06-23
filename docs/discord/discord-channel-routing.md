# 🗺️ Profile-to-Channel Mapping Guide for Discord

This guide explains how to configure a **NousResearch Hermes Agent** profile to map to a specific Discord channel or thread. This is ideal for teams or developers who want separate profiles (e.g. `urvets-api`, `nestjs-expert`, or `default`) to operate independently, routing status updates, cron outputs, and conversation histories to dedicated channels.

---

## 🔍 How Channel-Based Routing Works

In Discord:
* Every text channel and thread channel has a unique snowflake ID.
* When a message is sent or a cron job is triggered, Hermes uses the platform's `HOME_CHANNEL` environment variable (`DISCORD_HOME_CHANNEL`) to determine where to dispatch outputs.
* By using Discord's built-in **Channel Permissions**, you can restrict which bot (and thus which Hermes profile) can see or interact with a channel.
* For threads under a main channel, you can configure the specific thread ID in `DISCORD_HOME_CHANNEL_THREAD_ID`.

---

## 🛠️ Step-by-Step Setup

### 1. Retrieve Your Discord Channel/Thread ID

1. Open your Discord client.
2. Ensure **Developer Mode** is enabled under **User Settings** → **Advanced** → **Developer Mode**.
3. Right-click on the target channel or thread in the channel list and select **Copy Channel ID** (or **Copy Thread ID**).
4. The copied value is a long number like `112233445566778899`.

---

### 2. Locate Your Profile Config File

Hermes maintains a separate environment file for each profile under the `data/` folder:
* **Default profile**: `data/.env`
* **Custom profiles**: `data/profiles/<profile-name>/.env` (e.g., `data/profiles/urvets-api/.env`)

---

### 3. Update the Profile's `.env` File

Add or edit the following variables in the profile's `.env` file to configure channel routing and reply behavior:

```ini
# The primary Discord channel ID where the bot operates
DISCORD_HOME_CHANNEL=112233445566778899
DISCORD_HOME_CHANNEL_NAME=UrVets-API

# Optional: The designated thread ID for this profile's outputs/cron triggers
# (Used if the home channel is a thread, or you want cron reports sent to a thread)
DISCORD_HOME_CHANNEL_THREAD_ID=998877665544332211

# Bot reply mode (first, all, off)
# - first: Reply anchor is only set for the first message in a response chain
# - all: Reply anchor is set for every message chunk
# - off: Reply anchors are suppressed entirely
DISCORD_REPLY_TO_MODE=first
```

---

## 🛡️ Access Control & Process Isolation

Unlike Telegram, Discord has a robust native permissions system. To segregate multiple bots:
1. Create a Discord **Role** for each bot (e.g. `Hermes Default Bot Role`, `Hermes Programmer Bot Role`).
2. Go to the channel settings (e.g. `#programmer-expert`) → **Permissions**.
3. Add the default bot role or default bot user and set **View Channel** to **False (X)**.
4. Add the programmer bot role or user and set **View Channel** to **True (Check)**.
5. Doing this prevents cross-talk and ensures that each bot only listens to messages and commands in its designated channel, without running into duplicate reply issues!

---

## 🧪 Verification

1. Start or restart your gateway:
   ```bash
   docker exec hermes /command/s6-svc -t /run/service/gateway-<profile-name>
   ```
2. Send a message or mention the bot in its configured channel:
   * **Example**: `@your_bot hello`
   * The bot should respond directly in that channel.
3. Verify that the bot cannot read or reply in channels where its permissions are disabled.
