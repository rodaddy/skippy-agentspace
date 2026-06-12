# Phase 15: Hardening - Research

**Researched:** 2026-03-08
**Domain:** Shell configuration management, version automation, bash scripting
**Confidence:** HIGH

## Summary

Phase 15 addresses two independent hardening tasks: (1) replacing hardcoded angle-bracket placeholders in deploy-service with a shell-sourceable `config.env` mechanism, and (2) creating a `bump-version.sh` script that atomically updates all 25+ version locations across the repo.

Both tasks are well-scoped with prior research in STACK.md, ARCHITECTURE.md, and FEATURES.md already providing detailed designs. The deploy-service config work is confined to 5 files within `skills/deploy-service/` plus a `.gitignore` addition. The version bump work touches `tools/bump-version.sh` (new) and reads/writes `marketplace.json` + 12 `SKILL.md` files. Both follow established project patterns: `#!/usr/bin/env bash`, sourcing `tools/lib/common.sh`, and no external dependencies.

**Primary recommendation:** Implement as two independent plans -- config.env first (smaller blast radius, self-contained in deploy-service), bump-version.sh second (wider reach across repo, depends on common.sh).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| HARD-01 | deploy-service uses shell-sourceable `config.env` with validation (replaces 9 hardcoded placeholders) | Placeholder inventory (10 unique placeholders across 5 files), config.env variable design, validation pattern with `:?` parameter expansion, sourcing pattern with error messaging |
| HARD-02 | Version bump script updates VERSION file + all 25 version locations across 13 files | Version location inventory (25 in production files: 13 in marketplace.json + 12 in SKILL.md), marketplace.json as canonical source, sed/jq update strategy, dry-run pattern |
| HARD-03 | `config.env.example` committed, `config.env` gitignored | .gitignore addition pattern, example file with documented variables and placeholder values |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 4+ (macOS: via brew) | Script runtime | Project constraint -- all tooling is bash scripts |
| jq | 1.7+ | JSON manipulation for marketplace.json | Already a prereq (prereqs.sh checks for it) |
| sed | BSD (macOS) / GNU (Linux) | YAML frontmatter version updates in SKILL.md | Already used throughout project tooling |
| common.sh | N/A | Shared functions (skippy_pass/warn/fail/summary) | Phase 11 established this pattern for all tools/ scripts |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| grep | BSD/GNU | Verification of placeholder removal and version consistency | Post-bump validation |
| diff | standard | Dry-run output showing what would change | bump-version.sh --dry-run |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| shell-sourceable config.env | JSON + jq | JSON requires jq for every read. config.env is `source` -- zero-cost in bash. Infrastructure config is flat key=value, not nested. |
| sed for SKILL.md versions | bun script | Would add Node.js dependency for 3 lines of sed. Violates "no build step" constraint. |
| marketplace.json as version source | VERSION file | VERSION would be a 26th location needing sync. marketplace.json is already read by Claude Code's plugin system -- it IS the canonical version. |
| jq for marketplace.json | sed with regex | jq is safer for JSON manipulation (handles quoting, escaping). Already a project prerequisite. |

**Installation:**
```bash
# No new dependencies -- jq and bash already required by prereqs.sh
```

## Architecture Patterns

### Recommended Project Structure

```
skills/deploy-service/
  config.env.example      # NEW - committed, documents all variables
  config.env              # NEW - gitignored, user creates from example
  scripts/
    find-next-ip.sh       # MODIFY - source config.env instead of inline placeholders
    install-base-stack.sh  # MODIFY - source config.env for vaultwarden URL
  references/
    deploy-workflow.md    # MODIFY - reference config.env variables instead of <your-*>
    nginx-proxy.conf      # MODIFY - reference config.env variables instead of <your-*>
    systemd-service.service  # NO CHANGE - uses {{mustache}} template vars, not config
  SKILL.md                # MODIFY - document config.env setup

tools/
  bump-version.sh         # NEW - version bump automation
  lib/
    common.sh             # EXISTING - sourced by bump-version.sh
```

### Pattern 1: Shell-Sourceable Config with Validation

**What:** A `config.env` file containing `KEY=value` pairs, sourced directly by bash scripts with `:?` parameter expansion for required-value validation.

**When to use:** Flat infrastructure configuration that scripts need at runtime.

**Example:**
```bash
# config.env.example (committed)
# deploy-service configuration
# Copy to config.env and fill in your values.
# config.env is gitignored -- never commit real values.

# Proxmox host IP
DEPLOY_SERVER_IP=""

# Domain (wildcard SSL, e.g., example.com)
DEPLOY_DOMAIN=""

# ...more variables...
```

```bash
# In scripts that need config:
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../config.env"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: config.env not found." >&2
    echo "  Copy config.env.example to config.env and fill in your values." >&2
    exit 1
fi

source "$CONFIG"

# Validate required values with :? parameter expansion
: "${DEPLOY_SERVER_IP:?DEPLOY_SERVER_IP not set in config.env}"
: "${DEPLOY_DOMAIN:?DEPLOY_DOMAIN not set in config.env}"
```

### Pattern 2: Common.sh Sourcing with Graceful Fallback

**What:** All tools/ scripts source common.sh with an inline fallback if the file is missing.

**When to use:** Every new script in tools/ (established in Phase 11).

**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source shared library with graceful fallback
_COMMON_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    # shellcheck source=lib/common.sh
    source "$_COMMON_SH"
else
    # Minimal fallback stubs
    SKIPPY_PASS=0; SKIPPY_WARN=0; SKIPPY_FAIL=0
    skippy_repo_root() { cd "$(dirname "$0")/.." && pwd; }
    skippy_pass() { echo "  PASS: $1"; SKIPPY_PASS=$((SKIPPY_PASS + 1)); }
    skippy_fail() { echo "  FAIL: $1"; SKIPPY_FAIL=$((SKIPPY_FAIL + 1)); }
    skippy_section() { echo "=== $1 ==="; }
    skippy_summary() { echo "$SKIPPY_PASS passed, $SKIPPY_FAIL failures"; [[ "$SKIPPY_FAIL" -eq 0 ]]; }
fi
```

### Pattern 3: Atomic Multi-File Version Bump

**What:** Read current version from marketplace.json, compute new version, update all locations with jq (JSON) and sed (YAML), verify counts match expected.

**When to use:** Version bumps across marketplace.json (13 locations) + SKILL.md files (12 locations).

**Example:**
```bash
# Read canonical version
CURRENT=$(jq -r '.metadata.version' "$REPO_ROOT/.claude-plugin/marketplace.json")

# Compute new version
IFS='.' read -r major minor patch <<< "$CURRENT"
case "$BUMP_TYPE" in
    patch) patch=$((patch + 1)) ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    major) major=$((major + 1)); minor=0; patch=0 ;;
esac
NEW="$major.$minor.$patch"

# Update marketplace.json (all 13 version fields)
jq --arg v "$NEW" '(.metadata.version = $v) | (.plugins[].version = $v)' \
    "$MARKETPLACE" > "$MARKETPLACE.tmp" && mv "$MARKETPLACE.tmp" "$MARKETPLACE"

# Update SKILL.md frontmatter (12 files)
for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
    sed -i '' "s/  version: $CURRENT/  version: $NEW/" "$skill_md"
done
```

### Anti-Patterns to Avoid

- **Putting validation functions in common.sh:** deploy-service validation is domain-specific. Do not pollute the shared library with deploy-specific code. Validation stays inline in the scripts that need it, or in a deploy-service-local helper.
- **Using a VERSION file as source of truth:** Creates a 26th location that needs syncing. marketplace.json IS the source -- bump-version.sh reads from it and propagates everywhere else.
- **Non-prefixed config variable names:** Using `DOMAIN` or `NET1` risks collisions with other env vars. Use `DEPLOY_` prefix for all config.env variables.
- **Editing marketplace.json with sed:** JSON manipulation with sed is fragile (quoting, whitespace). Use jq -- it's already a project prerequisite.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON version update | sed regex on JSON | jq --arg with in-place update | jq handles quoting, escaping, whitespace correctly. sed on JSON is fragile. |
| Semver parsing | Custom regex | `IFS='.' read -r major minor patch` | Bash built-in string splitting. Covers M.m.p format which is all this project uses. |
| Config file validation | Custom parser | `:?` parameter expansion | Bash built-in. `${VAR:?message}` exits with error if VAR is unset or empty. Zero code needed. |
| Cross-platform sed | Detecting GNU vs BSD sed | `sed -i '' "..."` (macOS) | Project targets macOS (Darwin). All existing scripts use BSD sed syntax. |

**Key insight:** Both tasks are pure bash with zero external dependencies beyond jq (already required). No Node.js, no Python, no build step. The project's existing patterns cover every technical need.

## Common Pitfalls

### Pitfall 1: BSD sed -i Requires Empty String Argument
**What goes wrong:** `sed -i "s/old/new/"` works on GNU sed but fails on macOS BSD sed which requires `sed -i '' "s/old/new/"`.
**Why it happens:** macOS ships BSD sed, not GNU sed. The `-i` flag syntax differs.
**How to avoid:** Always use `sed -i '' "..."` since project targets macOS (Darwin 25.3.0). All existing scripts already use this pattern.
**Warning signs:** `sed: 1: "...": invalid command code` error.

### Pitfall 2: Sourcing User Config Files is a Code Execution Vector
**What goes wrong:** `source config.env` executes arbitrary bash if the config file contains commands.
**Why it happens:** bash `source` executes the file, not just reads variables.
**How to avoid:** For this project, this is acceptable -- config.env is a local file the user creates themselves. Document in config.env.example that it should only contain KEY=value assignments. Do NOT add complex sanitization -- it would fight the "source is zero-cost" benefit and this is a single-user private repo.
**Warning signs:** Unexpected output during script startup.

### Pitfall 3: jq In-Place Writes Need Temp File
**What goes wrong:** `jq '...' file > file` truncates the file before jq reads it.
**Why it happens:** Shell redirect opens the output file (truncating it) before jq starts reading.
**How to avoid:** Write to temp file, then mv: `jq '...' file > file.tmp && mv file.tmp file`.
**Warning signs:** Empty marketplace.json after a failed bump.

### Pitfall 4: YAML Frontmatter Version Sed Must Be Specific
**What goes wrong:** `sed "s/0.1.0/0.2.0/g"` replaces ALL occurrences of the version string in a file, not just the frontmatter.
**Why it happens:** SKILL.md files might reference version numbers in body text.
**How to avoid:** Anchor the sed pattern: `sed "s/  version: 0.1.0/  version: 0.2.0/"` -- matches only the YAML frontmatter indentation pattern. The two-space indent + `version:` key is unique to frontmatter.
**Warning signs:** Version strings changed in prose sections of SKILL.md.

### Pitfall 5: Placeholder Count Discrepancy
**What goes wrong:** Requirements say "9 hardcoded placeholders" but actual grep reveals 10 unique `<your-*>` patterns.
**Why it happens:** The count may have excluded `<your-vaultwarden-url>` (only in install-base-stack.sh) or counted `<your-network-1>` and `<your-network-2>` as one.
**How to avoid:** Map ALL unique placeholders to config variables. The actual inventory is 10 unique placeholders needing 10 config variables. The "9" in requirements is approximate -- implement all 10.
**Warning signs:** Grep for `<your-` returning matches after implementation.

### Pitfall 6: migrate.md Contains Hardcoded Version Instruction
**What goes wrong:** `skills/skippy/commands/migrate.md` line 105 instructs the AI to use `version: 0.1.0` when creating new skills. After a bump, newly migrated skills get the old version.
**Why it happens:** This is an instruction template, not a version declaration, so it was missed in the 25-location count.
**How to avoid:** bump-version.sh should also update this file. It's a 26th location (or treat it as part of the 25 -- the count in prior research was from production files only). Add it to the bump scope.
**Warning signs:** New skills created after a version bump show the old version.

## Code Examples

### config.env.example Template
```bash
# deploy-service configuration
# Copy to config.env and fill in your values.
# config.env is gitignored -- never commit real values.
#
# All DEPLOY_* variables are required unless marked optional.

# Proxmox host IP (the machine running pct commands)
DEPLOY_SERVER_IP=""

# Wildcard SSL domain (e.g., example.com)
DEPLOY_DOMAIN=""

# Reverse proxy LXC
DEPLOY_PROXY_VMID=""        # VMID of the nginx proxy container
DEPLOY_PROXY_IP=""          # IP address of the proxy (for DNS entries)

# Network ranges (first 3 octets, e.g., 10.0.1)
DEPLOY_NET1=""
DEPLOY_NET2=""
DEPLOY_GATEWAY=""           # Default gateway IP

# DNS server VMIDs (space-separated, e.g., "101 102")
DEPLOY_DNS_VMIDS=""

# Vaultwarden URL (for bitwarden CLI config in new containers)
DEPLOY_VAULTWARDEN_URL=""
```

### Config Sourcing in find-next-ip.sh
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/../config.env"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: config.env not found at $CONFIG" >&2
    echo "  Copy config.env.example to config.env and fill in your values." >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG"

# Validate required variables
: "${DEPLOY_NET1:?DEPLOY_NET1 not set in config.env}"
: "${DEPLOY_NET2:?DEPLOY_NET2 not set in config.env}"

for i in {13..254}; do
    if ! ping -c 1 -W 1 "${DEPLOY_NET1}.${i}" >/dev/null 2>&1 && \
       ! ping -c 1 -W 1 "${DEPLOY_NET2}.${i}" >/dev/null 2>&1; then
        echo "$i"
        exit 0
    fi
done

echo "ERROR: No available IPs found" >&2
exit 1
```

### bump-version.sh Core Logic
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source shared library
_COMMON_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
if [[ -f "$_COMMON_SH" ]]; then
    source "$_COMMON_SH"
else
    # minimal fallback
    skippy_repo_root() { cd "$(dirname "$0")/.." && pwd; }
fi

REPO_ROOT="$(skippy_repo_root)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

# Read canonical version from marketplace.json
CURRENT=$(jq -r '.metadata.version' "$MARKETPLACE")

# Parse args
DRY_RUN=false
BUMP_TYPE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --patch)   BUMP_TYPE="patch"; shift ;;
        --minor)   BUMP_TYPE="minor"; shift ;;
        --major)   BUMP_TYPE="major"; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Usage: bump-version.sh --patch|--minor|--major [--dry-run]"; exit 1 ;;
    esac
done

[[ -z "$BUMP_TYPE" ]] && echo "ERROR: Specify --patch, --minor, or --major" && exit 1

# Compute new version
IFS='.' read -r major minor patch <<< "$CURRENT"
case "$BUMP_TYPE" in
    patch) patch=$((patch + 1)) ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    major) major=$((major + 1)); minor=0; patch=0 ;;
esac
NEW="$major.$minor.$patch"

echo "Version bump: $CURRENT -> $NEW ($BUMP_TYPE)"

# Collect files to update
FILES=()
FILES+=("$MARKETPLACE")
for f in "$REPO_ROOT"/skills/*/SKILL.md; do
    FILES+=("$f")
done
# Also update migrate.md instruction template
MIGRATE_MD="$REPO_ROOT/skills/skippy/commands/migrate.md"
[[ -f "$MIGRATE_MD" ]] && FILES+=("$MIGRATE_MD")

if $DRY_RUN; then
    echo ""
    echo "Files that would change:"
    for f in "${FILES[@]}"; do
        echo "  ${f#$REPO_ROOT/}"
    done
    echo ""
    echo "No files modified (dry run)."
    exit 0
fi

# Update marketplace.json (jq)
jq --arg v "$NEW" '(.metadata.version = $v) | (.plugins[].version = $v)' \
    "$MARKETPLACE" > "$MARKETPLACE.tmp" && mv "$MARKETPLACE.tmp" "$MARKETPLACE"

# Update SKILL.md frontmatter (sed)
for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
    sed -i '' "s/  version: $CURRENT/  version: $NEW/" "$skill_md"
done

# Update migrate.md template version
if [[ -f "$MIGRATE_MD" ]]; then
    sed -i '' "s/version: $CURRENT/version: $NEW/" "$MIGRATE_MD"
fi

# Verify
REMAINING=$(grep -r "$CURRENT" "$REPO_ROOT/.claude-plugin/" "$REPO_ROOT/skills/*/SKILL.md" 2>/dev/null | wc -l)
echo "Updated: $CURRENT -> $NEW"
echo "Remaining old version references: $REMAINING"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Angle-bracket placeholders | Shell-sourceable config.env | Phase 15 (this phase) | Users fill config once, all scripts read it |
| Manual version editing across 25 files | Atomic bump-version.sh | Phase 15 (this phase) | One command updates everywhere |
| VERSION file as source of truth | marketplace.json metadata.version | Phase 15 design decision | Fewer locations to sync, plugin system reads it directly |

**Deprecated/outdated in prior research:**
- FEATURES.md proposed `deploy-service.conf` naming -- superseded by `config.env` per REQUIREMENTS.md
- ARCHITECTURE.md proposed `deploy.conf` naming -- superseded by `config.env` per REQUIREMENTS.md
- STACK.md proposed `VERSION` file as source of truth -- superseded by marketplace.json per ROADMAP success criteria
- STACK.md called the script `version-bump.sh` -- superseded by `bump-version.sh` per ROADMAP success criteria
- FEATURES.md proposed `DEPLOY_NET1_PREFIX` variable name -- use `DEPLOY_NET1` per ARCHITECTURE.md (simpler)

## Placeholder Inventory (deploy-service)

Complete inventory of `<your-*>` placeholders across all deploy-service files:

| Placeholder | Config Variable | Files Where It Appears |
|-------------|----------------|----------------------|
| `<your-server-ip>` | `DEPLOY_SERVER_IP` | SKILL.md, deploy-workflow.md (x7) |
| `<your-domain>` | `DEPLOY_DOMAIN` | SKILL.md (x2), deploy-workflow.md (x7), nginx-proxy.conf (x4) |
| `<your-proxy-host>` | (removed -- use DEPLOY_PROXY_VMID) | SKILL.md |
| `<your-proxy-vmid>` | `DEPLOY_PROXY_VMID` | deploy-workflow.md (x4) |
| `<your-proxy-ip>` | `DEPLOY_PROXY_IP` | deploy-workflow.md |
| `<your-network-1>` | `DEPLOY_NET1` | find-next-ip.sh, deploy-workflow.md |
| `<your-network-2>` | `DEPLOY_NET2` | find-next-ip.sh, deploy-workflow.md |
| `<your-gateway>` | `DEPLOY_GATEWAY` | deploy-workflow.md |
| `<your-dns-servers>` | `DEPLOY_DNS_VMIDS` | SKILL.md, deploy-workflow.md |
| `<your-vaultwarden-url>` | `DEPLOY_VAULTWARDEN_URL` | install-base-stack.sh |

**Total: 10 unique placeholders mapping to 10 config variables** (requirements say "9" -- all 10 should be implemented).

**Note on `<your-proxy-host>` vs `<your-proxy-vmid>`:** SKILL.md mentions `<your-proxy-host>` while deploy-workflow.md uses `<your-proxy-vmid>`. These map to the same config variable `DEPLOY_PROXY_VMID` -- the workflow uses VMIDs for `pct exec` commands.

## Version Location Inventory (bump-version.sh)

| File | Count | Format | Update Method |
|------|-------|--------|---------------|
| `.claude-plugin/marketplace.json` | 13 | `"version": "0.1.0"` (1 metadata + 12 plugins) | jq |
| `skills/core/SKILL.md` | 1 | `  version: 0.1.0` (YAML frontmatter) | sed |
| `skills/skippy/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/add-todo/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/browser/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/check-todos/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/correct/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/deploy-service/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/excalidraw/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/fabric/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/session-wrap/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/update-todo/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| `skills/vaultwarden/SKILL.md` | 1 | `  version: 0.1.0` | sed |
| **Total production locations** | **25** | | |
| `skills/skippy/commands/migrate.md` | 1 | `version: 0.1.0` (template instruction) | sed |
| **Grand total** | **26** | | |

**Files NOT to update** (these are in .planning/ -- historical docs, not production):
- `.planning/phases/*/` -- research and plan files reference versions as historical context
- `.planning/research/` -- architectural research docs

## Open Questions

1. **Should config.env variables use `DEPLOY_` prefix?**
   - What we know: ARCHITECTURE.md uses `DEPLOY_` prefix, STACK.md uses unprefixed names
   - What's unclear: Which the user prefers
   - Recommendation: Use `DEPLOY_` prefix -- prevents namespace collisions when scripts source the file. More explicit about which system the vars belong to.

2. **Should bump-version.sh create a git tag?**
   - What we know: STACK.md mentions git tagging, ROADMAP success criteria do not require it
   - What's unclear: Whether tagging is desired now or deferred
   - Recommendation: Include `--tag` flag as optional behavior, not default. Keep scope minimal per success criteria.

3. **How should deploy-workflow.md reference config variables?**
   - What we know: deploy-workflow.md is a reference doc (AI reads it), not an executable script. It contains code blocks with `<your-*>` placeholders.
   - What's unclear: Should code blocks use `${DEPLOY_SERVER_IP}` (assumes config sourced) or keep `<your-server-ip>` with a note to source config?
   - Recommendation: Replace placeholders with `${DEPLOY_*}` variable references and add a setup note at top: "Source config.env before executing these commands." This makes the workflow immediately executable after config setup.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bats-core (Phase 12, not yet implemented) |
| Config file | None -- Phase 12 will create test infrastructure |
| Quick run command | `bats tests/bump-version.bats` (when tests exist) |
| Full suite command | `bats tests/` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HARD-01 | config.env sourced with validation | manual + smoke | `grep -r '<your-' skills/deploy-service/` returns 0 matches | N/A -- grep verification |
| HARD-02 | bump-version.sh updates all 25+ locations | smoke | `bash tools/bump-version.sh --dry-run --patch` | Wave 0 |
| HARD-03 | config.env.example committed, config.env gitignored | smoke | `git check-ignore skills/deploy-service/config.env` returns 0 | N/A -- git verification |

### Sampling Rate

- **Per task commit:** `grep -r '<your-' skills/deploy-service/` (zero matches = pass)
- **Per task commit:** `bash tools/bump-version.sh --dry-run --patch` (shows files without error)
- **Phase gate:** All grep verifications pass, dry-run succeeds

### Wave 0 Gaps

- [ ] No bats test files exist yet (Phase 12 scope) -- all verification is manual/grep-based for Phase 15
- [ ] bump-version.sh should be self-verifying (count replacements, report mismatches)

## Sources

### Primary (HIGH confidence)

- `.planning/research/ARCHITECTURE.md` lines 380-534 -- deploy-service config design, version bump design
- `.planning/research/FEATURES.md` lines 213-300 -- deploy-service config, version bump feature specs
- `.planning/research/STACK.md` lines 275-457 -- config mechanism selection, version management design
- `.planning/REQUIREMENTS.md` lines 94-98 -- HARD-01, HARD-02, HARD-03 definitions
- `.planning/ROADMAP.md` lines 243-252 -- Phase 15 success criteria (governing authority for naming)
- Direct codebase grep for `<your-` and `0.1.0` -- actual file inventory

### Secondary (MEDIUM confidence)

- Existing tools/ scripts (verify.sh, install.sh) -- common.sh sourcing pattern, established conventions
- `.gitignore` -- current security patterns that config.env addition must not disrupt

### Tertiary (LOW confidence)

- None -- all findings verified against actual codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- pure bash, no new dependencies, all patterns established in prior phases
- Architecture: HIGH -- three prior research docs (ARCHITECTURE, FEATURES, STACK) already designed both features
- Pitfalls: HIGH -- all identified from actual codebase analysis and known bash gotchas

**Research date:** 2026-03-08
**Valid until:** Indefinite -- bash patterns are stable, codebase structure is well-established
