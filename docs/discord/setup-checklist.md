# 📝 Step-by-Step Setup Checklist: Multiple Discord Bots with Channel/Thread Routing

Follow these exact steps chronologically to set up and run multiple Discord bots corresponding to different Hermes profiles inside a single Discord server.

---

## 🏁 Phase 1: Discord Bot & Server Preparation

- [ ] **Step 1: Create Bot A (Default Profile)**
  * Go to the [Discord Developer Portal](https://discord.com/developers/applications).
  * Click **New Application**, name it (e.g. `Hermes Default Bot`), and create it.
  * Go to the **Bot** tab on the left menu, click **Add Bot** (if prompted), and copy its secret **Token** (Token A).
- [ ] **Step 2: Create Bot B (Programmer Expert Profile)**
  * Go back to the developer applications list and click **New Application** again.
  * Name it (e.g. `Hermes Programmer Bot`), create it, and copy its secret **Token** (Token B).
- [ ] **Step 3: Enable Privileged Gateway Intents for Both Bots**
  * For both applications, navigate to the **Bot** tab.
  * Scroll down to **Privileged Gateway Intents** and toggle **ON**:
    * **Presence Intent**
    * **Server Members Intent**
    * **Message Content Intent** (Crucial for reading commands and chat history!)
  * Click **Save Changes**.
- [ ] **Step 4: Invite Both Bots to Your Server**
  * Under each application, navigate to **OAuth2** → **URL Generator**.
  * Under **Scopes**, select `bot` and `applications.commands`.
  * Under **Bot Permissions**, select:
    * `Read Messages/View Channels`
    * `Send Messages`
    * `Send Messages in Threads`
    * `Read Message History`
  * Copy the generated URL at the bottom, paste it into your browser, and authorize it to add the bot to your target Discord Server.
- [ ] **Step 5: Enable Developer Mode in Discord**
  * In your Discord client, open **User Settings** (gear icon) → **Advanced**.
  * Toggle **Developer Mode** to **ON**. This allows you to right-click channels, users, and categories to copy their IDs.
- [ ] **Step 6: Retrieve Channel and Thread IDs**
  * Right-click on your target channels (e.g., `#general` and `#programmer-expert`) and select **Copy Channel ID**.
  * The ID is a long numeric snowflake (e.g., `112233445566778899`).
  * If using threads, create a thread in the channel and copy its Thread ID the same way.

---

## ⚙️ Phase 2: Hermes Profile Configuration

- [ ] **Step 7: Configure Bot A (Default)**
  * Run the interactive setup script:
    ```bash
    ./setup-discord.sh
    ```
  * Select `default` as the profile name and enter Token A and the Channel ID for `#general`.
- [ ] **Step 8: Configure Bot B (Programmer Expert)**
  * Run the interactive setup script again:
    ```bash
    ./setup-discord.sh
    ```
  * Select `programmer-expert` as the profile name and enter Token B and the Channel ID for `#programmer-expert`.

---

## 🚀 Phase 3: Start and Verify

- [ ] **Step 9: Deploy / Restart Services**
  * Restart both gateway profiles to load the new credentials and channel configuration:
    ```bash
    # Restart the default gateway
    docker exec hermes /command/s6-svc -t /run/service/gateway-default
    
    # Restart the programmer-expert gateway
    docker exec hermes /command/s6-svc -t /run/service/gateway-programmer-expert
    ```
- [ ] **Step 10: Test Default Bot Routing**
  * Go to the channel configured for the default bot (e.g., `#general`).
  * Send a message: `@Hermes Default Bot hello`
  * **Expected Result**: Default Bot (Bot A) replies in the channel. Programmer Bot (Bot B) remains silent.
- [ ] **Step 11: Test Programmer Bot Routing**
  * Go to the channel configured for the programmer bot (e.g., `#programmer-expert`).
  * Send a message: `@Hermes Programmer Bot hello`
  * **Expected Result**: Programmer Bot (Bot B) replies in `#programmer-expert`. Default Bot (Bot A) remains silent.
- [ ] **Step 12: Verify User Authorization (Gating)**
  * If a user not in `DISCORD_ALLOWED_USERS` attempts to trigger the bot (and `DISCORD_ALLOW_ALL_USERS` is not set to true), the bot should ignore them in public channels or prompt them with a pairing code in direct messages.
