---
phase: 15-hardening
plan: 01
subsystem: infra
tags: [deploy-service, config, shell, env-vars, security]

# Dependency graph
requires:
  - phase: 09-skill-system
    provides: deploy-service skill with placeholder pattern
provides:
  - config.env mechanism replacing all <your-*> placeholders in deploy-service
  - Shell-sourceable configuration with :? validation
affects: [deploy-service, 15-02]

# Tech tracking
tech-stack:
  added: []
  patterns: [config.env sourcing with SCRIPT_DIR-relative path, :? parameter validation]

key-files:
  created:
    - skills/deploy-service/config.env.example
  modified:
    - skills/deploy-service/scripts/find-next-ip.sh
    - skills/deploy-service/scripts/install-base-stack.sh
    - skills/deploy-service/references/deploy-workflow.md
    - skills/deploy-service/references/nginx-proxy.conf
    - skills/deploy-service/SKILL.md
    - .gitignore

key-decisions:
  - "config.env.example committed with empty defaults -- users copy to config.env (gitignored)"
  - "Scripts use SCRIPT_DIR-relative path to config.env for portability"
  - ":? parameter expansion for required variable validation with clear error messages"

patterns-established:
  - "Config sourcing pattern: SCRIPT_DIR -> CONFIG -> existence check -> source -> :? validation"

requirements-completed: [HARD-01, HARD-03]

# Metrics
duration: 4min
completed: 2026-03-08
---

# Phase 15 Plan 01: Deploy-Service Config Externalization Summary

**Shell-sourceable config.env mechanism replacing all <your-*> placeholders across 5 deploy-service files with DEPLOY_* variable references**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-08T21:09:18Z
- **Completed:** 2026-03-08T21:13:03Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Created config.env.example with all 9 DEPLOY_* variables documented with descriptions and example formats
- config.env gitignored so real infrastructure values are never committed
- Both scripts (find-next-ip.sh, install-base-stack.sh) source config.env with missing-file error and :? validation
- All <your-*> placeholders eliminated from deploy-service (zero grep matches)
- deploy-workflow.md uses ${DEPLOY_*} variables with prerequisites note
- nginx-proxy.conf uses ${DEPLOY_DOMAIN} while preserving {{mustache}} per-deployment vars

## Task Commits

Each task was committed atomically:

1. **Task 1: Create config.env.example and gitignore config.env** - `38febd8` (feat)
2. **Task 2: Replace placeholders with config.env sourcing** - `18b24b1` (feat)

## Files Created/Modified
- `skills/deploy-service/config.env.example` - Configuration template with all 9 DEPLOY_* variables
- `skills/deploy-service/scripts/find-next-ip.sh` - Sources config.env, validates DEPLOY_NET1/NET2
- `skills/deploy-service/scripts/install-base-stack.sh` - Sources config.env, validates DEPLOY_VAULTWARDEN_URL
- `skills/deploy-service/references/deploy-workflow.md` - All placeholders replaced with ${DEPLOY_*} vars
- `skills/deploy-service/references/nginx-proxy.conf` - <your-domain> replaced with ${DEPLOY_DOMAIN}
- `skills/deploy-service/SKILL.md` - Config section now references config.env setup
- `.gitignore` - Added skills/deploy-service/config.env entry

## Decisions Made
- config.env.example uses empty string defaults (e.g., `DEPLOY_SERVER_IP=""`) rather than example values to avoid accidental use of demo data
- Scripts use `SCRIPT_DIR` relative path (`$SCRIPT_DIR/../config.env`) for portability across installations
- `:?` parameter expansion provides clear error messages naming the missing variable and its config file

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Plan verification expected `grep -c "DEPLOY_" | grep -q "10"` but the spec defines 9 unique variables (two placeholders map to DEPLOY_PROXY_VMID). Resolved by including DEPLOY_* in header comment for accurate count.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- deploy-service config externalization complete
- Ready for Plan 02 (remaining hardening tasks)

---
*Phase: 15-hardening*
*Completed: 2026-03-08*
