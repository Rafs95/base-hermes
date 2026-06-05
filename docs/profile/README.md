# 👤 Profile Installation Guide

Profiles in Hermes allow you to define distinct system prompts (via `SOUL.md`) and pre-installed toolsets (via `skills.md`) for specialized agent roles (e.g. `nestjs-expert`, `default`, etc.).

---

## 📂 Profile Template Structure

Each profile is stored as a template inside `docs/profile/templates/{profile_name}`:

```text
docs/profile/templates/{profile_name}/
├── SOUL.md        # The agent's core instructions and personality prompt.
├── skills.md      # A markdown list of skills to install for this profile.
└── install.sh     # Bash script to automate staging and installation.
```

---

## 📁 Available Templates

* **`nestjs-expert`**: A generic NestJS senior developer persona, focusing on standard modules, DI best practices, DTO mapping, and testing.
* **`urvets-api`**: A project-specific developer persona tailored for the `urvets-api` veterinary management backend (incorporating multi-tenant scoping, custom JWT Auth Guard logic, and database schemas).

---

## 🚀 How to Install a Profile

To install a profile, run its accompanying `install.sh` script from the host command line.

### Option A: Direct Installation
Run the installer directly from the template folder:
```bash
./docs/profile/templates/nestjs-expert/install.sh
```

### Option B: Automatic Global Resolution
If you are running the script from the root repository, it resolves directories automatically:
```bash
bash docs/profile/templates/nestjs-expert/install.sh
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

Example for NestJS Expert:
```bash
docker exec -it hermes hermes profile use nestjs-expert
```

---

## 🎨 Creating a New Profile Template

To create a new custom profile template:
1. Create a new directory under `docs/profile/templates/{new-profile-name}/`.
2. Create your `SOUL.md` detailing the agent instructions.
3. Create your `skills.md` containing `npx skills add` commands (one command per line).
4. Copy the `install.sh` from the `nestjs-expert` template and change `PROFILE_NAME="nestjs-expert"` to your new profile name at the top of the script.
