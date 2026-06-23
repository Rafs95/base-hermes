# 🤖 Hermes Agents Guide

This document details how agents are structured, configured, and custom-tailored in the **base-hermes** repository.

---

## 👤 Profile Persona & Persona Templates

Hermes agents are driven by custom Persona Profiles. Each profile is defined as a template inside `docs/profile/templates/{profile_name}`.

### 📂 Profile Template Layout

```text
docs/profile/templates/{profile_name}/
├── SOUL.md              # The agent's core instructions and personality prompt.
└── skills.md            # A markdown list of skills (one CLI command per line).
```

### 🚀 Installing Profiles

Instead of having duplicate installer scripts, a generalized script is provided at the root:

```bash
./docs/profile/install.sh <profile_name>
```

Refer to [docs/profile/README.md](file:///Users/raf/Development/base-hermes/docs/profile/README.md) for more information.

---

## 📏 Custom Agent Rules

This workspace utilizes custom agent instructions to guide AI coding assistants when modifying the repository or templates.

- **Profile Templates Rules**: Rules for creating/modifying agent profile templates are located at [.agents/rules/profile-templates.md](file:///Users/raf/Development/base-hermes/.agents/rules/profile-templates.md).
