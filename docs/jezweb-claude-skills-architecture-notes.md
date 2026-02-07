# Why jezweb/claude-skills is structured the way it is (and what it implies)

**Scope:** This note explains the *design intent* behind the repo’s marketplace + per-skill plugin manifests, based on these repo docs:

- `docs/PLUGIN_ARCHITECTURE.md`
- `docs/SKILLS_COMMANDS_ARCHITECTURE.md`
- `docs/PLUGIN_INSTALLATION_GUIDE.md`
- `docs/MARKETPLACE.md`

It also cross-checks those claims against the **official Claude Code plugin reference**.

---

## 1) The core constraint he is designing around

### A. Claude Code plugin discovery is *root-oriented*
Official docs describe plugin-provided components as living at **specific directories at the plugin root** (e.g., `agents/`, `commands/`, `skills/`). If you put these directories somewhere else (e.g., nested deep inside other folders), Claude Code won’t discover them unless you explicitly add *custom component paths* in `plugin.json`.

Official reference:
- Skills live under `<plugin>/skills/<skill-name>/SKILL.md` (or legacy `<plugin>/commands/*.md`).
- Agents live under `<plugin>/agents/*.md`.
- The `.claude-plugin/` folder is only for metadata (`plugin.json`); other component directories must be at the **plugin root**.

This root-level assumption is why “nested commands/agents inside each skill folder” is a tricky layout for a *single* “bundle” plugin.

### B. His repo-level doc states “no recursive search”
In `PLUGIN_ARCHITECTURE.md`, he states Claude Code “does NOT recursively search nested directories” and gives the concrete consequence:

> If your plugin has `skills/my-skill/commands/`, those commands will NOT be discovered. Commands must be at `[plugin-root]/commands/`.

That is the key “why” behind the rest of his architecture.

---

## 2) The architecture he chose

### A. One marketplace, many installable plugins
He distinguishes two things:

- **Marketplace** = catalog of plugins
- **Installation** = actually enabling a plugin

He emphasizes that listing something in `marketplace.json` doesn’t install it. Users install **specific plugins**.

### B. A “bundle plugin” for skills + separate “individual plugins” for command/agent extras
He describes 3 patterns:

1) **Bundle install** (`all@...`) – “gets everything” (skills), but **nested** commands/agents aren’t discovered  
2) **Individual skill install** – install just the skill plugin for the ones that have commands/agents  
3) **Hybrid** – install `all` to get skills, then install specific plugins to get their commands/agents

This hybrid approach matches what the repo README tells users: install `all` for the background knowledge, then install select plugins for commands/agents.

**Design intent:** keep the big “skills library” convenient to install, but still allow “extras” (agents & commands) without flattening all agents/commands into one giant root folder (which would create naming conflicts and become messy).

---

## 3) Why the per-skill `.claude-plugin/plugin.json` generator exists

If he wants a skill directory like:

```
skills/cloudflare-worker-base/
  SKILL.md
  agents/
  commands/
  ...
```

…and he also wants **that folder** to be installable as a plugin, then it needs:

```
skills/cloudflare-worker-base/
  .claude-plugin/plugin.json
```

That `plugin.json` can declare custom paths like `"agents": "./agents/"` and `"commands": "./commands/"`.

So: the generator script is there so *each skill directory becomes a valid “plugin root”* for individual installs.

---

## 4) Where his docs appear inconsistent with the official spec

There are a couple “red flags” where the repo docs don’t align cleanly with the official plugin reference:

### A. `plugin.json` “skills” and “agents” examples that look like *names*, not *paths*
`PLUGIN_INSTALLATION_GUIDE.md` shows a manifest example like:

```json
{
  "skills": ["cloudflare-worker-base"],
  "agents": ["cloudflare-deploy", "worker-scaffold"]
}
```

In the official schema, `skills`, `agents`, and `commands` are **paths (string | array of strings)**, not arrays of names. So that snippet reads like a conceptual example rather than a schema-accurate one.

### B. “Skills can contain commands/ directory for `/skill/command`”
`SKILLS_COMMANDS_ARCHITECTURE.md` describes an internal convention where a skill can have `commands/` and be invoked like `/skill/command`.

Official docs do confirm “commands have been merged into skills” (skills and legacy commands both create `/name`), but the official “plugins reference” still models commands at the plugin root (and skills at `<plugin>/skills/<name>/SKILL.md`). The “`/skill/command`” form is not clearly established in the official docs, so treat that part as either:
- an implementation detail he observed in specific Claude Code versions, or
- a repo convention/aspiration rather than a guaranteed API contract.

---

## 5) What this means for *your* manifest generator script

If your script is designed for the **same hybrid architecture**, the direction is basically sound:

- Generating `.claude-plugin/plugin.json` per skill folder supports “install individual skill plugin”
- Setting `"agents": "./agents/"` and `"commands": "./commands/"` is consistent with the official manifest schema *as paths*

But:
- Don’t describe `agents` as “must be directory path, not array of names.” Officially it can be `string | array`, and arrays are paths too.
- If you want the *skill itself* to load when installing the per-skill plugin, you need to ensure the per-skill plugin exposes skills via the standard layout (`skills/<skill>/SKILL.md`) or via a correct `"skills": "./somewhere/"` path to a directory that contains skill directories.

In the repo’s “hybrid” approach, the per-skill plugin may be intended primarily for **commands/agents**, while the skill content is provided by the `all` bundle. If you want “individual install = includes the skill”, you need to be more careful with skill paths.

---

## 6) Bottom line

He structured the repo this way to reconcile two competing goals:

1) **Install convenience:** one command to get a large library of skills (bundle plugin)
2) **Root-level discovery constraints:** commands/agents are easiest when they live at plugin root, so “skills that have extras” are also shipped as individual plugins whose *plugin root = that skill folder*

That is why you see:
- a bundle plugin (e.g., `all`)
- many per-skill plugin manifests
- guidance to do a hybrid install for commands/agents

---

## References (official docs)

- Plugins reference: https://code.claude.com/docs/en/plugins-reference  
- Create & distribute a marketplace: https://code.claude.com/docs/en/plugin-marketplaces  
- Skills: https://code.claude.com/docs/en/skills
