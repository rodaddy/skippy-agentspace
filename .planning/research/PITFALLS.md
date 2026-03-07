# Domain Pitfalls

**Domain:** Portable Claude Code skill marketplace augmenting upstream frameworks (GSD, PAUL)
**Researched:** 2026-03-06
**Confidence:** HIGH (project-specific code analysis + verified Claude Code documentation + upstream issue tracker)

## Critical Pitfalls

Mistakes that cause rewrites, silent failures, or fundamental breakage.

### Pitfall 1: Hardcoded Absolute Paths in Commands

**What goes wrong:** Commands reference files via absolute paths like `@/Users/rico/.config/pai/Skills/skippy-dev/references/reconciliation.md`. Any user who isn't Rico gets silent "file not found" failures. When installed as a plugin, Claude Code copies the plugin directory to `~/.claude/plugins/cache/` -- absolute paths pointing outside that cache break because external files aren't copied.

**Why it happens:** Skills were developed in PAI's installed location first, then extracted to the agentspace repo. Paths point to the installed copy, not the skill's own directory. This works perfectly in development but fails in every other context.

**How to avoid:**
- Use `${CLAUDE_SKILL_DIR}` for paths in SKILL.md content
- Use relative paths from command files to reference docs (e.g., `../references/reconciliation.md`)
- Everything a skill needs must be inside its own directory -- no references outside `skills/<name>/`

**Warning signs:**
- `grep -r "/Users/" skills/` returns any matches
- Commands work on development machine but fail after fresh clone + install
- Plugin install succeeds but skill invocation produces empty/confused output

**Phase to address:**
Phase 1 (spec compliance) -- portability audit before any other work. This is the single most impactful fix.

---

### Pitfall 2: Context Window Budget Exhaustion from Skill Metadata + Reference Docs

**What goes wrong:**
Two separate budget problems compound:

1. **Skill metadata budget:** Claude Code allocates ~15,000-16,000 characters (2% of context window) for ALL skill descriptions. Each skill consumes ~109 chars overhead + full description length. At average 263-char descriptions, only ~42 skills fit. Beyond that, skills are silently excluded -- no error, they simply become invisible and untriggerable. Empirical research showed 33% of installed skills (21 of 63) completely hidden at this threshold.

2. **Reference doc loading:** The `@file` directives in command files (e.g., reconcile.md loads SKILL.md + reconciliation.md + state-consistency.md) inject full content into the active context window. Five reference docs averaging 70 lines each consume ~3,500 tokens per invocation. Stack multiple skill invocations in one session and context fills fast.

**Why it happens:**
- Skill descriptions are written for human readability, not token efficiency
- No feedback loop shows "this invocation consumed 4,000 tokens of reference docs"
- The 42-skill visibility cap hits silently -- `/context` shows a warning but most users never run it
- Reference doc loading via `@file` is invisible in the conversation

**How to avoid:**
- Cap skill descriptions at 130 characters maximum. Front-load trigger keywords in first 50 characters
- Budget the marketplace: 130-char descriptions fit ~67 skills. Plan around that ceiling
- Use progressive disclosure for reference docs: SKILL.md gives the rules, references load only when the specific enhancement is relevant (not all 5 at once)
- Run `/context` after installing skills to verify none are truncated
- Set `SLASH_COMMAND_TOOL_CHAR_BUDGET` as a last resort, not a first move
- Consider `disable-model-invocation: true` for skills that should only be invoked manually

**Warning signs:**
- `/context` shows "Showing X of Y skills due to token limits"
- Skills stop auto-triggering that previously worked
- Sessions feel sluggish or context compresses earlier than expected
- Reference-heavy commands produce lower quality output in DEEP context brackets

**Phase to address:**
Phase 1 (skill anatomy) -- establish description length limits and reference loading discipline before creating new skills.

---

### Pitfall 3: Command Naming Collisions -- Silent Override Cascade

**What goes wrong:**
Three collision vectors, all silent:

1. **Project overrides global:** A `.claude/commands/cleanup.md` in any project silently overrides global `~/.claude/commands/skippy/cleanup.md`. No warning. The project command just wins. Affects 1-in-5 developers in team settings (SFEIR research).

2. **Reserved name collision:** A command named `/skill` (matching Claude Code's built-in Skill tool) causes ALL custom commands to fail to load -- not just the conflicting one. Confirmed bug (GitHub #13586). Similar reserved names: `/init`, `/compact`, `/review`, `/memory`, `/clear`, `/context`, `/help`, `/logout`, `/login`, `/config`, `/doctor`, `/cost`, `/permissions`, `/mcp`, `/vim`, `/terminal-setup`.

3. **Plugin prefix stripping:** When SKILL.md frontmatter includes a `name` field, it can bypass the expected `plugin:skill` namespace prefix (GitHub #22063). A skill meant to appear as `/skippy:reconcile` might appear as just `/reconcile`, colliding with other commands.

4. **Skill-command precedence:** If a skill at `~/.claude/skills/reconcile/SKILL.md` and a command at `~/.claude/commands/reconcile.md` both exist, the skill takes precedence. The command silently stops working.

**Why it happens:**
- Claude Code's resolution order is undocumented and has changed between versions
- No collision detection in install tooling
- Developers name commands after what they do (`cleanup`, `update`, `init`) -- these are the most collision-prone words
- The `name` field in frontmatter has unexpected namespace-flattening behavior

**How to avoid:**
- Enforce `<skillname>:` prefix on ALL commands. The current `skippy:reconcile` pattern is correct -- never allow bare names
- `tools/install.sh` must check for existing commands at target path before symlinking and warn on collision
- Maintain a reserved-names list and check against it during install
- `tools/index-sync.sh` should validate no two skills share command names
- Test commands in a fresh Claude Code session after install

**Warning signs:**
- A command that works in one project but not another
- Running a command and getting unexpected behavior (wrong skill responded)
- ALL commands stop loading after adding a new skill (reserved name collision)
- `tools/install.sh` succeeds but command doesn't appear in `/` tab completion

**Phase to address:**
Phase 1 (install tooling) -- collision detection must be built in before multi-skill support ships.

---

### Pitfall 4: Plugin System File Copying Breaks External References

**What goes wrong:** When Claude Code installs a plugin, it copies the plugin directory to `~/.claude/plugins/cache/`. Files that reference things outside the plugin directory (like `../shared-utils` or absolute paths) break because external files aren't copied. Symlinks within the plugin directory ARE followed during copying, but symlinks pointing outside are not.

**Why it happens:** Plugins are designed to be self-contained. The copy mechanism ensures portability but doesn't follow references outside the plugin root.

**How to avoid:**
- Everything a skill needs must live inside its own directory. No references outside `skills/<name>/`
- Test by installing via `/plugin install` in a fresh environment (not on the development machine)
- If sharing resources between skills, copy them into each skill directory (duplication is acceptable for portability)

**Warning signs:**
- Skill installs without error but scripts fail at runtime
- Works in development (where files exist at referenced path) but breaks when installed as plugin
- Error messages about missing files that definitely exist "right there"

**Phase to address:**
Phase 1 (spec compliance + portability audit).

---

### Pitfall 5: Using Non-Spec Frontmatter Fields

**What goes wrong:** Current SKILL.md uses `triggers:` in frontmatter. This field is not part of the Agent Skills spec and is not recognized by Claude Code. It gets silently ignored. Claude uses the `description` field for discovery, not `triggers`.

**Why it happens:** The skill was created before the Agent Skills spec was finalized. `triggers:` was a PAI-specific convention that felt logical.

**How to avoid:**
- Only use spec-defined frontmatter fields: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`
- For Claude Code extensions: `disable-model-invocation`, `user-invocable`, `context`, `agent`, `model`, `hooks`, `argument-hint`
- Move trigger keywords into the `description` field where Claude actually reads them

**Warning signs:**
- Skills don't auto-trigger despite having seemingly correct frontmatter
- Other Agent Skills-compatible tools (Codex, Gemini CLI) ignore or error on the skill

**Phase to address:**
Phase 1 (spec compliance).

---

### Pitfall 6: Upstream Version Tracking with `/tmp` and `source`-ing Unvalidated Files

**What goes wrong:**
The current `skippy-update.sh` has three structural problems:

1. **`/tmp` is volatile.** Cloned repos in `/tmp/skippy-upstream/` vanish on reboot (macOS clears `/tmp` aggressively). When combined with short-hash version tracking, old hashes may not exist in the fresh clone. `git diff "${gsd_hash}..HEAD"` fails silently (the `|| echo` fallback hides the real error), producing "(full diff unavailable)" -- which looks like an upstream problem when it's a local storage problem.

2. **`source "$VERSIONS_FILE"` is unsafe.** The `.versions` file is `source`-d directly into bash. If the file is malformed (truncated write, disk error, manual edit), arbitrary code could execute. More practically, a comment or extra line causes bash to try executing it as a command.

3. **Short hashes are ambiguous.** `git rev-parse --short HEAD` produces 7-char hashes. As repos grow, short hash collisions become possible. More importantly, short hashes can't reliably be used in `git diff` if the ref isn't in the local clone's history (which happens after `/tmp` cleanup + re-clone).

**Why it happens:**
- `/tmp` feels right for "temporary clones" but the versions file creates a dependency on those clones persisting
- `source` is the simplest way to read key=value files in bash
- Short hashes are more readable but less reliable as persistent identifiers

**How to avoid:**
- Move upstream clones to `~/.cache/skippy-upstream/` (persistent, user-private)
- Replace `source "$VERSIONS_FILE"` with explicit parsing: `gsd_hash=$(grep '^gsd_hash=' "$VERSIONS_FILE" | cut -d= -f2)`
- Use full SHA hashes (`git rev-parse HEAD`) for storage. Display short hashes for humans
- Add `git fetch --unshallow` or sufficient depth after re-clone for meaningful diffs
- Validate the versions file format before reading

**Warning signs:**
- "(full diff unavailable)" appears when upstream definitely has changes
- Script works for weeks then produces empty diffs after a reboot
- `skippy-update.sh` shows "CHANGES DETECTED" but diff is empty

**Phase to address:**
Phase 1 or 2 (script hardening) -- fix before regular workflow use. The `/tmp` issue bites on first macOS reboot.

---

## Moderate Pitfalls

### Pitfall 7: Parasitic Coupling to GSD Internal File Layout

**What goes wrong:** The skippy-dev skill assumes specific GSD file structures: `.planning/STATE.md` has a `current_phase` field, `.planning/ROADMAP.md` exists with a specific format, `.planning/phases/<N>/PLAN.md` and `SUMMARY.md` follow conventions. If GSD renames a field, restructures directories, or changes how phase completion is tracked, every reference doc that reads those files breaks silently.

This isn't hypothetical. GSD's changelog shows the `depth` to `granularity` rename, executor agents now updating ROADMAP.md (behavior reconciliation assumes doesn't happen), and path changes from `~/.claude/` to `$HOME/.claude/`.

**Why it happens:**
- The "parasitic" architecture is correct for maintenance but means zero control over the host's internals
- GSD changes are absorbed manually via `/skippy:update`, but there's no automated check that reference docs still match GSD's file layout
- The update script tracks commit hashes but doesn't analyze whether changes affect integration points

**How to avoid:**
- Document every GSD assumption in a `DEPENDENCIES.md`: "assumes STATE.md has `current_phase`", "assumes phases at `.planning/phases/<N>/`"
- `/skippy:update` should flag changes to GSD files that skippy-dev depends on (maintain an integration-point file list)
- Reference docs should use defensive language: "Look for `current_phase`. If absent, check for alternative phase tracking"
- Pin to a known-good GSD version and test against it

**Warning signs:**
- `/skippy:reconcile` produces empty or nonsensical reports
- State consistency checker flags everything as misaligned
- `/skippy:update` shows changes in GSD's state management or template files

**Phase to address:**
Phase 2 (upstream monitoring enhancement). Phase 3 (testing with GSD fixture project).

---

### Pitfall 8: Symlink Installation Creates Invisible Breakage

**What goes wrong:**

1. **Stale symlinks after repo move.** If `skippy-agentspace/` moves, all symlinks become dangling. Claude Code silently ignores broken symlinks.
2. **Relative vs absolute paths.** Relative symlinks break on directory changes. Absolute symlinks break on repo moves.
3. **Two-copy divergence.** The repo has skills at `skippy-agentspace/skills/skippy-dev/`, but commands reference `~/.config/pai/Skills/skippy-dev/`. Edits to one don't appear in the other.
4. **Parent directory creation.** If `~/.claude/commands/` doesn't exist, a naive `ln -s` creates a file-level symlink instead of directory-level, with different behavior.

**How to avoid:**
- `tools/install.sh` must use absolute paths and verify target exists before creating
- Add `tools/doctor.sh` that validates all symlinks resolve (like `brew doctor`)
- Choose one canonical location and make the other a symlink TO it
- After install, validate: `ls -la ~/.claude/commands/skippy/` confirms files are readable

**Warning signs:**
- Commands work on one machine but not another
- `ls -la ~/.claude/commands/skippy/` shows broken (red) symlinks
- Editing a reference doc in the repo doesn't affect behavior

**Phase to address:**
Phase 1 (install tooling).

---

### Pitfall 9: Reference Doc Staleness Creates False Confidence

**What goes wrong:** Reference docs encode workflows from PAUL and assumptions about Claude Code behavior. When either upstream changes, the docs become wrong but still look authoritative. A doc saying "Claude can't expose exact context usage" may become false when Claude Code adds context introspection. Agents follow outdated instructions, missing opportunities or producing suboptimal results.

**Why it happens:**
- Written once, rarely re-validated
- No `last_verified` date or `assumes` section in doc headers
- No mechanism to test "does this reference doc still produce good agent behavior?"

**How to avoid:**
- Add `last_verified`, `source`, and `assumes` metadata to every reference doc header
- Cite source with commit hash: "Adapted from PAUL's verification-protocol.md (commit abc1234)"
- `/skippy:update` should map reference docs to their PAUL sources and flag when those change
- Quarterly review cadence

**Warning signs:**
- Reference doc advice contradicts observed Claude Code behavior
- Agents follow instructions but produce worse results than without them
- PAUL repo rewrites a source document but reference doc still cites old version

**Phase to address:**
Phase 2 (reference doc quality). Phase 3 (upstream monitoring integration).

---

### Pitfall 10: Description Field Quality Determines Auto-Discovery

**What goes wrong:** Claude can't find your skill when it should, or triggers it when it shouldn't.

**Why it happens:** Claude's skill auto-loading uses the `description` field for semantic matching. Vague descriptions ("helps with development") match everything. Over-specific descriptions miss natural language requests.

**How to avoid:**
- Description should answer "what does it do" AND "when should Claude use it"
- Use format: "[Verb] [domain]. Use when: [trigger1], [trigger2]."
- Test by asking Claude natural questions that should trigger the skill

**Warning signs:**
- Skill never auto-triggers despite being relevant
- Skill triggers for unrelated requests

**Phase to address:**
Phase 1 (skill anatomy).

---

## Minor Pitfalls

### Pitfall 11: `bin/` vs `scripts/` Directory Naming

**What goes wrong:** Agent Skills spec defines `scripts/` as the conventional directory. Using `bin/` works in Claude Code but may not be recognized by other compatible tools.

**Prevention:** Rename `bin/` to `scripts/`.

### Pitfall 12: INDEX.md Drift

**What goes wrong:** INDEX.md lists skills that don't exist or misses new ones.

**Prevention:** Run `index-sync.sh --check` before commits. Consider a pre-commit hook.

### Pitfall 13: Upstream Repo URL Changes

**What goes wrong:** GSD already moved from `coleam00/` to `gsd-build/`. PAUL could move too. Hardcoded URLs in scripts break silently (clone fails, script continues with stale data).

**Prevention:** Store repo URLs in a config file, not hardcoded in scripts. Detect clone failures and error out explicitly.

### Pitfall 14: Version Mismatch Between plugin.json and marketplace.json

**What goes wrong:** Version in `marketplace.json` gets silently overridden by `plugin.json`. Users think they're pinning a version but the plugin manifest wins.

**Prevention:** Set version in ONE place only. Document which file is authoritative.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hardcoded paths in commands (`@/Users/rico/...`) | Works immediately on dev machine | Breaks for all other users and installed contexts | Never in a "portable" skill |
| `source`-ing `.versions` file | 2 lines of bash | Arbitrary code execution risk, fragile parsing | Never -- use `grep`/`cut` |
| Storing upstream clones in `/tmp` | No persistent storage | Clones vanish on reboot, diffs fail | Only if script handles re-clone gracefully (currently doesn't) |
| Dual-location skills (repo + PAI install) | Supports development and installed use | Sync confusion, edits in wrong copy | Only with clear "canonical = repo, installed = symlink" rule |
| Skipping collision detection in install | Faster install script | Silent command shadowing | Never once more than one skill exists |
| Non-spec frontmatter (`triggers:`) | Readable, self-documenting | Ignored by Claude Code, breaks other tools | Never -- move to `description` |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| GSD `.planning/` files | Assuming file format is stable | Document every assumed field/path, flag upstream changes |
| Claude Code commands dir | Using relative symlinks | Always absolute symlinks with target existence validation |
| PAUL repo concepts | Copy-pasting without attribution | Cite source commit hash for trackable drift detection |
| Skill metadata | Writing descriptions for humans | Write for semantic matching: verb + domain + triggers, 130 chars max |
| `~/.claude/commands/` namespace | Using generic names (`cleanup`, `update`) | Always use `skillname:commandname` prefix |
| Plugin cache copying | Referencing files outside plugin dir | Everything inside `skills/<name>/`, no external references |
| Agent Skills spec frontmatter | Using PAI-specific fields (`triggers:`) | Only spec-defined fields, validated before publish |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading all 5 reference docs per command | Context fills 30% faster, quality drops | Load only the relevant reference doc | At MODERATE context bracket (10+ file reads) |
| Cloning full upstream repos on every update | 30+ second execution, network dependency | `git fetch` on existing clones, `--depth=1` for initial | On slow/offline networks |
| `/skippy:reconcile` on projects with many phases | Agent reads every PLAN.md and SUMMARY.md | Scope to most recent phase by default, `--all` for full audit | At 5+ completed phases |
| Skill metadata growing with marketplace | Skills beyond budget cap become invisible | Monitor count vs budget, compress descriptions proactively | At ~42 skills (average desc) or ~67 (compressed) |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `source`-ing `.versions` file | Arbitrary code execution if tampered or malformed | Parse with `grep`/`cut`, never `source` |
| Upstream clones in `/tmp` (world-readable) | Other users on shared systems can read/modify repos | Use `~/.cache/` (user-private) |
| No target validation before symlinking | Could symlink to attacker-placed file | Validate target exists and is expected type |
| Blind installation of community skills | Prompt injection, data exfiltration | Audit skill code before installation, review what scripts touch |
| Over-permissive script execution | Scripts inherit user permissions, can delete files | Review file system access in each script |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Silent skill truncation at budget cap | User installs 50 skills, 8 are invisible | Install script estimates budget usage, warns before exceeding |
| No feedback on command collision | Project command silently overrides global skill | Install script checks for existing commands, warns |
| `/skippy:update` shows changes with empty diff | User can't see what changed upstream | Fix `/tmp` persistence so diffs work after reboot |
| All reference docs loaded when only one needed | Wasted context, slower responses | Load specific reference per task |
| Install requires re-run after repo changes | Edits don't take effect | Use symlinks to repo (not copies), verify chain |
| Non-spec frontmatter silently ignored | Trigger keywords don't work, no error | Use only spec-defined fields |

## "Looks Done But Isn't" Checklist

- [ ] **Portability:** `grep -r '/Users/rico\|/Volumes/ThunderBolt' skills/` returns zero results in command/reference files
- [ ] **Install script:** Not just "runs without error" -- verify symlinks resolve, parent dirs exist, no collisions detected
- [ ] **Skill descriptions:** Not just "written nicely" -- tested for semantic matching accuracy (does Claude actually trigger them for 3 different phrasings?)
- [ ] **Reference docs:** Not just "content is accurate" -- has `last_verified` date, source attribution, `assumes` section
- [ ] **Upstream monitoring:** Not just "script runs" -- reboot machine, run `/skippy:update`, confirm diffs still work
- [ ] **Index sync:** Not just "INDEX.md matches skills/" -- also checks for cross-skill command name collisions
- [ ] **Frontmatter:** Not just "YAML parses" -- validated against Agent Skills spec, no unsupported fields
- [ ] **Plugin install:** Not just "works in dev" -- tested via `/plugin install` in a fresh environment
- [ ] **Context budget:** Not just "current skills fit" -- projected budget usage documented for planned skill count
- [ ] **Namespace:** `skippy:` prefix verified against Claude Code reserved command names list

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Skills silently truncated | LOW | Compress descriptions, run `/context` to verify, set `SLASH_COMMAND_TOOL_CHAR_BUDGET` if needed |
| Command naming collision | LOW | Rename conflicting command, re-run install, verify in fresh session |
| Stale symlinks after repo move | LOW | Re-run `tools/install.sh` from new location |
| Reserved name collision (all commands break) | LOW | Rename the offending command to avoid reserved name, restart Claude Code |
| Upstream GSD breaking change | MEDIUM | Run `/skippy:update`, identify affected reference docs, update, test against real project |
| Reference doc gives outdated advice | MEDIUM | Trace to PAUL source, compare current, update doc, add `last_verified` |
| `/tmp` clone loss corrupts version tracking | LOW | Delete `.versions`, re-run `/skippy:update` to re-baseline (lose diff-against-previous) |
| Full context exhaustion from reference loading | HIGH | Session already degraded. `/session-wrap`, start fresh. Only prevention (selective loading) works |
| Plugin install breaks external references | MEDIUM | Move all referenced files inside skill directory, re-package, re-install |
| Non-spec frontmatter ignored | LOW | Replace `triggers:` with proper `description` keywords, validate against spec |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Hardcoded paths | Phase 1: Spec compliance | `grep -r '/Users/' skills/` returns zero matches |
| Context budget exhaustion | Phase 1: Skill anatomy | `/context` shows no truncation after install. Descriptions under 130 chars |
| Command naming collisions | Phase 1: Install tooling | `tools/install.sh` reports "no collisions found" |
| Plugin file copying breaks references | Phase 1: Self-containment | `/plugin install` works in fresh environment |
| Non-spec frontmatter | Phase 1: Spec compliance | Only spec-defined fields in all SKILL.md files |
| `/tmp` + `source` fragility | Phase 1-2: Script hardening | Reboot, run `/skippy:update`, confirm diffs work |
| GSD internal coupling | Phase 2: Dependency docs | `DEPENDENCIES.md` lists every assumed GSD field/path |
| Symlink installation | Phase 1: Install tooling | `tools/doctor.sh` passes on fresh clone + install |
| Reference doc staleness | Phase 2: Reference quality | Every reference doc has `last_verified`, `source`, `assumes` metadata |
| Description quality | Phase 1: Skill anatomy | Each skill's description tested for semantic matching against 3 trigger phrases |
| Upstream repo URL changes | Phase 2: Config externalization | Repo URLs in config file, not hardcoded |
| INDEX.md drift | Phase 1: Pre-commit validation | `index-sync.sh --check` passes in CI/hooks |

## Sources

- [SFEIR Institute: Custom Commands & Skills Common Mistakes](https://institute.sfeir.com/en/claude-code/claude-code-custom-commands-and-skills/errors/) -- 10 documented error patterns with severity ratings
- [Claude Code Skill Budget Research (alexey-pelykh)](https://gist.github.com/alexey-pelykh/faa3c304f731d6a962efc5fa2a43abe1) -- empirical measurement of 15,500 char budget, 42-skill visibility cap
- [Claude Code Official Docs: Skills](https://code.claude.com/docs/en/skills) -- skill structure, metadata format, budget scaling
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) -- file copying behavior, strict mode, version resolution, reserved names
- [Agent Skills Specification](https://agentskills.io/specification) -- directory naming, frontmatter constraints
- [GitHub Issue #13586: Naming conflict with built-in Skill tool](https://github.com/anthropics/claude-code/issues/13586) -- confirmed cascading ALL-commands failure
- [GitHub Issue #15842: Skill name blocks command invocation](https://github.com/anthropics/claude-code/issues/15842) -- skill/command namespace conflict
- [GitHub Issue #22063: Plugin skills lose prefix with name field](https://github.com/anthropics/claude-code/issues/22063) -- namespace-flattening bug
- [Tyler Folkman: Complete Guide to Claude Skills](https://tylerfolkman.substack.com/p/the-complete-guide-to-claude-skills) -- progressive disclosure, trigger reliability, budget overhead
- [alexop.dev: Claude Code Customization Guide](https://alexop.dev/posts/claude-code-customization-guide-claudemd-skills-subagents/) -- context drift, auto-trigger failures, subagent isolation
- [GSD Repository](https://github.com/gsd-build/get-shit-done) -- upstream change patterns, breaking changes (depth->granularity, path changes)
- [Claude Code plugin script path resolution bug](https://github.com/anthropics/claude-code/issues/11011) -- relative paths in plugins
- [Claude Code sub-agent skill loading issue](https://github.com/anthropics/claude-code/issues/10061) -- global vs project skill resolution
- Project-specific code analysis of `skippy-update.sh`, `skippy-cleanup.sh`, SKILL.md, all reference docs, and command files

---
*Pitfalls research for: Portable Claude Code skill marketplace (skippy-agentspace)*
*Researched: 2026-03-06*
