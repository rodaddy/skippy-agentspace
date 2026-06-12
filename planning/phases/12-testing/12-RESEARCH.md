# Phase 12: Testing - Research

**Researched:** 2026-03-08
**Status:** Complete
**Source:** Manual research (researcher agent timed out) + web search data

## Domain Analysis

### bats-core Framework

bats-core is a TAP-compliant testing framework for Bash 3.2+. Each `@test` block is a function that passes if all commands exit 0 (uses `set -e`).

**Installation options:**
1. `brew install bats-core` (macOS) -- simple but not reproducible in CI
2. Git submodules (recommended for projects) -- vendored, reproducible

**Recommended structure:**
```
tests/
  bats/                    <- submodule (bats-core)
  test_helper/
    bats-support/          <- submodule
    bats-assert/           <- submodule
    common.bash            <- shared setup
  common-lib.bats
  install.bats
  uninstall.bats
  ...
```

**Key helpers from bats-assert:**
- `assert_success` / `assert_failure` -- check `$status`
- `assert_output` / `refute_output` -- check `$output` (supports `--partial`)
- `assert_line` / `refute_line` -- check specific output lines

**Loading pattern:**
```bash
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}
```

**Gotcha:** `run cmd | grep x` doesn't work -- bash parses as `(run cmd) | grep x`. Wrap piped commands in a function.

### Scripts to Test (6 scripts + 1 library)

| Script | Lines | Key Behaviors | Test Priority |
|--------|-------|---------------|--------------|
| `tools/lib/common.sh` | 116 | Repo root, pass/warn/fail counters, summary, is_installed, color detection | HIGH -- foundation |
| `tools/install.sh` | 295 | Selective install (--core/--all/positional), symlink creation, idempotent | HIGH -- critical path |
| `tools/uninstall.sh` | 228 | Selective uninstall, readlink safety (71-skill nuke fix), clean removal | HIGH -- safety-critical |
| `tools/verify.sh` | 256 | Post-install verification, pass/fail reporting | MEDIUM |
| `tools/index-sync.sh` | 216 | INDEX.md generation, category grouping | MEDIUM |
| `tools/prereqs.sh` | 276 | Prerequisite checking, interactive prompts | LOW -- interactive, hard to test |
| `tools/validate-hooks.sh` | 313 | Hook validation, settings.json parsing | MEDIUM |

### Sandboxing Strategy

**CRITICAL:** All tests MUST override `HOME` to prevent touching real `~/.claude/`.

bats provides `$BATS_TEST_TMPDIR` -- unique temp directory per test, auto-cleaned.

```bash
setup() {
    export HOME="$BATS_TEST_TMPDIR"
    mkdir -p "$HOME/.claude/skills"
    mkdir -p "$HOME/.claude/commands"
}
```

This ensures:
- No test touches real `~/.claude/`
- Each test gets clean state
- Cleanup is automatic

### CI Integration

GitHub Actions macOS runner (`macos-latest` = macOS 14 Sonnet):
- Has `brew` pre-installed
- Bash 3.2 (system) + can install bash 5 via brew
- bats-core installable via `brew install bats-core`

But for reproducibility, using git submodules means CI just needs to `git submodule update --init`.

**Workflow pattern:**
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      - run: ./tests/bats/bin/bats tests/
```

### Test Count Estimation

| Test File | Estimated Tests | Coverage |
|-----------|----------------|----------|
| `common-lib.bats` | 8 | repo_root, pass/warn/fail, summary, is_installed, colors |
| `install.bats` | 8 | --core, --all, positional, idempotent, missing skill |
| `uninstall.bats` | 6 | single, --all, readlink safety, non-skippy symlinks preserved |
| `verify.bats` | 4 | clean install, missing skills, mixed state |
| `index-sync.bats` | 4 | generation, categories, empty skills dir |
| `validate-hooks.bats` | 4 | valid hooks, missing hooks, corrupt settings |
| **Total** | **~34** | All scripts except prereqs.sh |

prereqs.sh is interactive and checks system tools -- hard to unit test. Skip or minimal coverage.

## Validation Architecture

### Test Dimensions
1. **Sandboxing** -- every test uses `$BATS_TEST_TMPDIR` as HOME
2. **Clean clone** -- tests create their own fixtures, no pre-existing install needed
3. **TAP output** -- bats-core native, no configuration needed
4. **CI readiness** -- GitHub Actions workflow with submodule checkout

### Risk Areas
- `install.sh` reads `REPO_ROOT` via common.sh -- test must set up skills/ directory structure in temp
- `uninstall.sh` readlink check -- test must verify non-skippy symlinks survive `--all`
- `validate-hooks.sh` needs a mock `settings.json` -- create in `$HOME/.claude/`
- `common.sh` BASH_SOURCE path derivation won't work when sourced from tests/ -- need `SKIPPY_ROOT` env var fallback

### Known Gotchas (from project memory)
1. `((count++))` returns exit 1 when count=0, crashes under `set -e` (bats uses `set -e`)
2. `$0` vs `$BASH_SOURCE` -- context differs when code is inlined
3. `eval` in prereqs.sh -- injection vector, test if present
4. `.gitignore` regression -- security patterns must survive

## Recommendations

1. **Use git submodules** for bats-core, bats-support, bats-assert -- reproducible, no brew dependency for tests
2. **Shared test helper** at `tests/test_helper/common.bash` -- loads libraries, sets up sandboxed HOME, creates fixture directories
3. **One test file per script** -- clear ownership, parallel-safe
4. **Skip prereqs.sh** -- interactive tool checks are hard to unit test, low value
5. **Test the uninstall safety fix** explicitly -- the 71-skill nuke was the project's worst bug
6. **~34 tests** across 6 files hits the ~30 target

## RESEARCH COMPLETE

Research covers: bats-core setup, script inventory, sandboxing strategy, CI integration, test count estimation, and risk areas. Ready for planning.
