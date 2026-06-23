# 📏 Rules for Hermes Profile Templates

Follow these guidelines when creating, updating, or managing Hermes agent profile templates in this repository.

## 📖 Required References

- **SOUL Guide**: [Use SOUL with Hermes](https://hermes-agent.nousresearch.com/docs/guides/use-soul-with-hermes)

---

## 📂 File Structure

A profile template directory must be placed in `docs/profile/templates/{profile_name}/` and contain:
1. **`SOUL.md`**: Core system prompt / character persona.
2. **`skills.md`**: List of skill installation commands (one per line, starting with `npx skills add`).

---

## 🚫 Installer Rule

- **Do NOT create an `install.sh` file** inside the profile template folder.
- Installation is handled centrally by the generalized installer script: [docs/profile/install.sh](file:///Users/raf/Development/base-hermes/docs/profile/install.sh).

---

## 🛠️ Creating a New Profile Template

1. Create a new directory matching the profile name under `docs/profile/templates/`.
2. Author a descriptive `SOUL.md`.
3. List the requested skills in `skills.md`.
4. Test the installation from the root using:
   ```bash
   ./docs/profile/install.sh <new_profile_name>
   ```
