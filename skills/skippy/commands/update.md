---
name: skippy:update
description: Check all tracked upstreams for changes and suggest cherry-picks
---

<objective>
Check every registered upstream for new commits since the last check. Report changes grouped by area, highlight activity in cherry-picked regions, and suggest potential new cherry-picks. Update tracking state after each check.

No auto-merge -- present findings and let the user decide what to absorb.
</objective>

<execution_context>
@../SKILL.md
</execution_context>

<process>

## 1. Discover Upstreams

Read all `upstreams/*/upstream.json` files from the skippy-agentspace repo root. Each file contains:

- `name` -- upstream identifier (matches directory name)
- `repo` -- git clone URL
- `branch` -- branch to track (usually "main")
- `last_checked_sha` -- SHA from last check, or "none" if never checked
- `last_check` -- ISO 8601 date, or "never"
- `cherry_picks` -- array of ideas/features already extracted
- `notes` -- context about the relationship

Build a list of all upstreams to check. If `upstreams/` is empty or missing, report that no upstreams are registered and suggest running `mkdir upstreams/<name>` with an `upstream.json` file.

**Never hardcode repo URLs.** The upstream registry is the single source of truth.

## 2. Check Each Upstream

For each upstream in the registry:

1. Determine the cache directory: `~/.cache/skippy-upstream/<name>` (or `$SKIPPY_CACHE_DIR/<name>` if the env var is set)
2. If the cache directory does not exist, clone the repo there (`git clone --quiet <repo> <cache-dir>`)
3. If the cache directory exists, fetch the latest (`cd <cache-dir> && git fetch origin --quiet && git reset --hard origin/<branch> --quiet`)
4. Get the current HEAD SHA: `git rev-parse HEAD`
5. Compare against `last_checked_sha` from the upstream.json

Handle network failures gracefully -- if a clone or fetch fails, report the error for that upstream and continue checking others. Do not abort the entire update.

## 3. Report Changes

For each upstream, report one of:

**No changes:**
A brief line: "[name]: No changes since [last_check]"

**Changes detected:**
- Commit count since last check
- Date range of new commits
- Changed files grouped by area (e.g., "templates/", "workflows/", "hooks/")
- If the upstream has `cherry_picks` entries, highlight any changes touching those areas -- these are high-signal and may need attention
- Suggest potential new cherry-picks based on what looks interesting (new features, patterns, reference docs)

**First run (last_checked_sha is "none"):**
Note that this is the initial baseline. Show a summary of the repo structure and recent commits (last 10) to give context, but don't flag everything as "new."

## 4. Update Tracking

After checking each upstream, update its `upstream.json` file in-place:
- Set `last_checked_sha` to the current HEAD SHA
- Set `last_check` to today's date in ISO 8601 format (YYYY-MM-DD)
- Preserve all other fields unchanged

Write the JSON back with 2-space indentation and a trailing newline.

## 5. Cross-Package Analysis Flag

Check if `docs/cross-package-analysis.md` exists in the repo. If it does and any upstream shows significant changes (more than 10 commits, or changes in cherry-picked areas), suggest re-reviewing the cross-package analysis document. Note when it was last reviewed if that information is available in the document.

</process>
