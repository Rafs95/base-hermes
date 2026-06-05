# 📝 Step-by-Step Setup Checklist: Multiple Bots with Group Topics

Follow these exact steps chronologically to set up and run multiple Telegram bots corresponding to different Hermes profiles inside a single group chat using Topics.

---

## 🏁 Phase 1: Telegram Bot & Group Preparation

- [ ] **Step 1: Create Bot A (Default Profile)**
  * Go to Telegram and message [@BotFather](https://t.me/BotFather).
  * Send `/newbot`, name it (e.g. `Hermes Default Bot`), and save its API token (Token A).
- [ ] **Step 2: Create Bot B (UrVets API Profile)**
  * Message `@BotFather` again.
  * Send `/newbot`, name it (e.g. `Hermes UrVets Bot`), and save its API token (Token B).
- [ ] **Step 3: Enable Topics in your Group**
  * Create a new group or open an existing group.
  * Go to **Group Info** → **Edit** → **Topics** and toggle it **ON** to convert the group into a Forum Supergroup.
- [ ] **Step 4: Create Topics**
  * Create a topic named `UrVets-API` (or similar). The default main chat will act as the `General` topic.
- [ ] **Step 5: Add Both Bots to the Group**
  * Add both Bot A and Bot B to the group as members (or administrators to ensure full message access).
- [ ] **Step 6: Retrieve Topic Thread IDs**
  * Right-click or long-press on your topics (e.g., General and UrVets-API) and select **Copy Link**.
  * The link format looks like: `https://t.me/c/1234567890/2`
  * Extract the number at the end:
    * **General** thread ID (usually `1` or empty).
    * **UrVets-API** thread ID (usually `2`, `3`, etc.).

---

## ⚙️ Phase 2: Hermes Profile Configuration

- [ ] **Step 7: Configure Bot A (Default)**
  * Run the interactive setup script:
    ```bash
    ./installer/setup-telegram.sh
    ```
  * Select `default` as the profile name and enter Token A and Thread ID `1`.
- [ ] **Step 8: Configure Bot B (UrVets API)**
  * Run the interactive setup script again:
    ```bash
    ./installer/setup-telegram.sh
    ```
  * Select `urvets-api` as the profile name and enter Token B and Thread ID `2`.


---

## 🚀 Phase 3: Start and Verify

- [ ] **Step 9: Deploy / Restart Services**
  * Restart both gateway profiles to load the new credentials and topic routing:
    ```bash
    # Restart the default gateway
    docker exec hermes /command/s6-svc -t /run/service/gateway-default
    
    # Restart the urvets-api gateway
    docker exec hermes /command/s6-svc -t /run/service/gateway-urvets-api
    ```
- [ ] **Step 10: Test Default Bot Routing**
  * Go to the **General** topic (Thread ID `1`).
  * Send a message: `@default_bot_username hello`
  * **Expected Result**: Default Bot (Bot A) replies in General. UrVets Bot (Bot B) remains silent.
- [ ] **Step 11: Test UrVets Bot Routing**
  * Go to the **UrVets-API** topic (Thread ID `2`).
  * Send a message: `@urvets_bot_username hello`
  * **Expected Result**: UrVets Bot (Bot B) replies in the UrVets-API topic. Default Bot (Bot A) remains silent.
- [ ] **Step 12: Verify Topic Gating (Anti-Crosstalk)**
  * In the **UrVets-API** topic, send: `@default_bot_username hello`
  * **Expected Result**: Default Bot (Bot A) **must remain silent** because it is restricted to `TELEGRAM_ALLOWED_TOPICS=1`.
