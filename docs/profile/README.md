# 👤 Profile Installation Guide

Profiles in Hermes allow you to define distinct system prompts (via `SOUL.md`) and pre-installed toolsets (via `skills.md`) for specialized agent roles (e.g. `nestjs-expert`, `default`, etc.).

---

## 📂 Profile Template Structure

Each profile is stored as a template inside `docs/profile/templates/{profile_name}`:

```text
docs/profile/templates/{profile_name}/
├── SOUL.md        # The agent's core instructions and personality prompt.
└── skills.md      # A markdown list of skills to install for this profile.
```

---

## 📁 Available Templates

* **`programmer-expert`**: A general-purpose polyglot software engineering persona, focusing on software design principles, testing, clean code, and refactoring.

---

## 🚀 How to Install a Profile

To install a profile, run the general `install.sh` script from the host command line, passing the profile name as an argument.

### Usage
```bash
./docs/profile/install.sh <profile_name>
```

### Examples
To install `programmer-expert`:
```bash
./docs/profile/install.sh programmer-expert
```

---

## ⚙️ What the Installer Does

When you execute `install.sh`:
1. **Validates Connection**: Checks that the `hermes` Docker container is running.
2. **Stages Files**: Copies the files into a temporary staging folder in the mounted `data/` volume.
3. **Registers Profile**: Runs `hermes profile install` inside the container to unpack the files.
4. **Installs Skills**: Reads `skills.md` line-by-line, executing the `npx skills add` commands inside the container, and registers them.

---

## 💻 Switching to the Installed Profile

Once installed, you can tell the Hermes CLI to use this profile:

```bash
docker exec -it hermes hermes profile use {profile_name}
```

Example for Programmer Expert:
```bash
docker exec -it hermes hermes profile use programmer-expert
```

---

## 🎨 Creating a New Profile Template

To create a new custom profile template:
1. Create a new directory under `docs/profile/templates/{new-profile-name}/`.
2. Create your `SOUL.md` detailing the agent instructions.
3. Create your `skills.md` containing `npx skills add` commands (one command per line).

*(Note: No `install.sh` is needed for individual templates! The installer is fully generalized.)*
