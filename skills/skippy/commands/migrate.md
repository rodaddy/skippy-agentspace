---
name: skippy:migrate
description: Migrate PAI skills into portable format
---

<objective>
Scan ~/.config/pai/Skills/, rank candidates by priority, present for approval, and migrate approved skills to portable format under skills/. Handles directory flattening, SKILL.md slimming, private content sanitization, and integration file updates.

No auto-migration -- present findings and let the user decide what to migrate.
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>

## 1. Scan Source Skills

Read all directories under `~/.config/pai/Skills/`. For each:

1. Read the entry file (SKILL.md, or whatever main markdown exists)
2. Count total lines across all files in the directory tree
3. Identify subdirectory structure (Workflows/, Tools/, helpers/, templates/, agents/, config/, bin/)
4. Note file types and counts (markdown, shell scripts, TypeScript, JSON, etc.)

Check which skills already exist under `skills/` in this repo:
- If a skill name matches (case-insensitive), flag it as "already migrated"
- Offer re-migrate option for those (will overwrite existing)

Build a scan results table:

| Name | Files | Lines | Subdirs | Status |
|------|-------|-------|---------|--------|
| n8n | 12 | 1450 | Workflows/, Tools/ | new |
| deploy-service | 8 | 920 | helpers/, templates/ | new |
| skippy | 6 | 540 | commands/, references/ | already migrated |

## 2. Rank and Present Candidates

Sort candidates by priority using these criteria (highest first):

1. **Daily driver frequency** -- check against the user's CLAUDE.md "Skills You Keep Skipping" table. Skills listed there are highest priority since they're used constantly
2. **Foundational chain** -- skills that other skills depend on (e.g., deploy-service is used by many infrastructure skills)
3. **Portable value** -- how useful is this skill outside PAI? Skills tied to specific private infrastructure rank lower

Present a ranked table to the user:

| Rank | Name | Lines | Complexity | Category | Rationale |
|------|------|-------|------------|----------|-----------|
| 1 | n8n | 1450 | HIGH | domain | Daily driver, extensive workflow knowledge |
| 2 | deploy-service | 920 | MEDIUM | utility | Foundational, used by many skills |
| 3 | proxmox | 680 | MEDIUM | domain | Infrastructure-specific, moderate portability |

Complexity classification:
- **LOW**: <300 lines, flat structure, pure markdown
- **MEDIUM**: 300-1000 lines, 1-2 subdirs, some scripts
- **HIGH**: >1000 lines, deep subdirs, multiple file types

Flag duplicates interactively -- skills that overlap in purpose (e.g., CreateSkill vs create-skill-dm vs skill-add).

Wait for user to approve, reject, or adjust each candidate before proceeding.

## 3. Dry-Run Preview (per skill)

For each approved skill, show a migration preview before writing anything:

**Target file tree:**
```
skills/<name>/
  SKILL.md              (slimmed entry point)
  references/           (detailed content moved here)
  commands/             (if skill has slash commands)
  scripts/              (if skill has shell scripts)
```

**SKILL.md preview** -- show the first 30 lines of the generated SKILL.md with total line count. Must be <150 lines.

**What gets stripped:**
- PAI-specific references (paths to ~/.config/pai-private/, PAI-only integrations)
- Private content (IPs, domains, server names, credentials)
- Non-portable dependencies (PAI-only MCP servers, private APIs)

**What gets flattened** (directory mapping):
- `Workflows/` -> `references/`
- `Tools/` -> `scripts/` (shell) or `references/` (markdown)
- `helpers/` -> `scripts/`
- `templates/` -> `references/`
- `agents/` -> `references/`
- `config/` -> `references/`
- `bin/` -> `scripts/`

Wait for user confirmation before writing each skill.

## 4. Migrate (per approved skill)

For each confirmed skill:

**Create target directory:**
```bash
mkdir -p skills/<name>/references skills/<name>/commands skills/<name>/scripts
```

**Create SKILL.md** (slimmed to <150 lines):
- Frontmatter: name, description, metadata (version: 0.1.0, author, source, category)
- Keep: description paragraph, quick reference table, common operations, reference file list, top-5 gotchas
- Move to references/: detailed workflows, extended gotchas, code examples, config details, long tables

**Flatten directories** per the mapping in step 3. Preserve file names within the flattened structure.

**Sanitize private content** using these regex replacements:
- IPs: Private IP patterns (e.g., `10\.x\.y\.z`) -> `<your-server-ip>`
- Domains: Private domain patterns -> `<your-domain>`
- Credential names matching known patterns -> `<your-credential>`
- Server/host names matching known infrastructure -> `<your-host>`
- Paths: `~/.config/pai-private/` references -> note as "PAI-private, not included"

**Add gap notes** where PAI-specific features were stripped:
```markdown
> **PAI enhancement available:** [feature] requires PAI infrastructure. See PAI docs for setup.
```

**Normalize naming:**
- Directory name: lowercase-kebab (e.g., Art -> art, CreateSkill -> create-skill)
- Keep internal file names as-is unless they conflict

**Skip non-portable files:**
- node_modules/, bun.lock, .DS_Store, compiled artifacts (.js from .ts)
- Binary files, cache directories, lock files

**Remove empty directories** after migration (commands/ or scripts/ if nothing was placed there).

## 5. Update Integration Files

After all approved skills are migrated:

**Update marketplace.json:**
Add a plugin entry for each newly migrated skill in `.claude-plugin/marketplace.json`.

**Rebuild INDEX.md:**
Run `tools/index-sync.sh --generate` to rebuild with new skills included in their categories.

**Migration summary report:**
```
=== Migration Complete ===
Skills migrated: 3
  - n8n (domain) -- 12 files, 1450 -> 890 lines
  - deploy-service (utility) -- 8 files, 920 -> 420 lines
  - proxmox (domain) -- 6 files, 680 -> 350 lines
Total files created: 26
Warnings: 2 (see above)
Next: Review each skills/<name>/SKILL.md and adjust as needed
```

</process>
