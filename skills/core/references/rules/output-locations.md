# Output Location Conventions

Rules for where generated files, reports, and artifacts should be placed.

## Reports

Reports go to a centralized location outside the project directory:

<!-- CUSTOMIZE: reports_base_dir (default: Development/.reports/) -->
```
<reports_base_dir>/<project-name>/
```

**Rules:**
- Centralized -- all project reports in one directory tree
- No dates in filenames -- overwrite previous reports
- Never use `~` or `/tmp` for reports
- Never use `<project>/.reports/` (keeps project directories clean)

**Example:**
```
Development/.reports/my-project/coverage.html
Development/.reports/my-project/lint-report.json
```

## Session Artifacts

Session-related files (checkpoints, session history) follow the project's
planning structure:

```
<project>/.planning/     # Planning artifacts (phases, state, roadmap)
<project>/.omc/          # OMC session artifacts (if using OMC)
```

## Generated Files

Build artifacts, compiled output, and generated code follow standard conventions:

- `dist/` or `build/` for compiled output
- `.gitignore` must cover all generated directories
- Never commit build artifacts to version control

## Secrets and Credentials

- Never in git -- use `.env` files (gitignored) or a secrets manager
- See LAW 11 for enforcement details
