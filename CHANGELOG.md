# Changelog

All notable changes to skippy-agentspace are documented here.

## [1.2.0] - 2026-03-22

### Added
- 103 structural assertions across 22 categories (`evals/structural/runner.sh`)
- Behavioral eval suites for install experience (16 assertions) and repo quality (12 assertions)
- CI job runs structural evals on every push/PR
- VERSION file for semantic versioning
- GLOSSARY.md for ubiquitous language
- 8 new skills in marketplace.json (brain, capture-session, gh-review, prd, prd-to-issues, session-handoff, session-start, ubiquitous-language)
- gstack and superpowers upstream registrations
- Quick Start section in CLAUDE.md

### Fixed
- uninstall.sh: now removes copied directories, not just symlinks
- uninstall.sh: fallback function matches install.sh behavior
- uninstall.sh: interactive read guarded with terminal check for CI/automation
- uninstall.sh: shellcheck error (local outside function)
- install.sh: trap handler for cleanup of temporary backup dirs
- install.sh: backup naming collision (added PID suffix)
- install.sh: error messages now suggest available skills
- install.sh: dead code removed (unused install_skill_copy, COPY_MODE)

### Changed
- Eval runner split into modular category files (LAW 9 compliance)
- CLAUDE.md file tree updated to reflect all 24 skills
- INDEX.md regenerated with full skill inventory
- planner.md and researcher.md agents: added complexity: field

### Enriched
- trace SKILL.md: example output + reading guide (+38 lines)
- vaultwarden SKILL.md: 3 new gotchas + service patterns (+18 lines)
- correct SKILL.md: For Agents section (+13 lines)
- 3 SKILL.md files: added metadata blocks (prd, prd-to-issues, ubiquitous-language)

## [1.1.0] - 2026-03-08

### Added
- Portable PAI: 12 skills, upstream tracking, bootstrap installer
- Shared shell library (tools/lib/common.sh) with skippy_* helpers
- .gitattributes with export-ignore entries

## [1.0.0] - 2026-03-07

### Added
- Initial release: spec, packaging, commands, documentation
- 16 phases planned, core framework established
