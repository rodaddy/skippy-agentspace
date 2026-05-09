<!-- Extracted from SKILL.md -- load on demand -->

# Test Scenarios Battery

## Hook Enforcement Tests

Each test: pipe JSON stdin to hook script, check exit code.

### pre-ancient-bash-blocker.ts (LAW 7)

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H01 | Write with `#!/bin/bash` in content | exit 2 (block) | Should catch wrong shebang |
| H02 | Write with `#!/usr/bin/env bash` in content | exit 0 (allow) | Should allow correct shebang |
| H03 | Edit replacing text with `#!/bin/bash` in new_string | exit 2 (block) | Should catch in edits too |
| H04 | Write with `#!/bin/sh` in content | exit 0 (allow) | sh is allowed, only bash blocked |

### pre-bash-protected-branch-commit.ts (LAW 8)

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H05 | Bash `git commit` when on `main` | exit 2 (block) | Should block commits on main |
| H06 | Bash `git commit` when on `wip/test` | exit 0 (allow) | Should allow on feature branches |
| H07 | Bash `git commit` when on `develop` | exit 2 (block) | develop is also protected |
| H08 | Bash `git commit` when on `feat/new-thing` | exit 0 (allow) | feat/ prefix should pass |

### pre-bash-destructive-git.ts

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H09 | Bash `git reset --hard HEAD~1` | exit 2 (block) | Hard reset must be blocked |
| H10 | Bash `git push --force origin main` | exit 2 (block) | Force push must be blocked |
| H11 | Bash `git clean -f` | exit 2 (block) | Clean force must be blocked |
| H12 | Bash `git branch -D feature` | exit 2 (block) | Branch delete must be blocked |
| H13 | Bash `git push origin main` | exit 0 (allow) | Normal push should pass |
| H14 | Bash `git checkout .` | exit 2 (block) | Discard changes must be blocked |

### pre-python3-blocker.ts

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H15 | Bash `python3 -c "print('hello')"` | exit 2 (block) | Direct python3 must be blocked |
| H16 | Bash `claudePy -c "print('hello')"` | exit 0 (allow) | claudePy is the right tool |
| H17 | Bash `ssh host "python3 script.py"` | exit 0 (allow) | Remote python3 is fine |
| H18 | Bash `which python3` | exit 0 (allow) | Querying python3 path is fine |

### pre-mcp2cli-enforcer.ts

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H19 | Tool `mcp__n8n-mcp__n8n_list_workflows` | exit 2 (block) | n8n is in mcp2cli, should redirect |
| H20 | Tool `mcp__qmd__search` | exit 0 (allow) | qmd is in ALWAYS_ALLOW |
| H21 | Tool `mcp__vaultwarden-secrets__get_credential` | exit 0 (allow) | VW MCP tools are allowed |

### pre-skill-enforcer.ts

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H22 | Bash `ssh root@<N8N_IP> "systemctl restart n8n"` without /n8n skill in recent | exit 2 (block) | n8n ops need the skill first |
| H23 | Same command WITH /n8n skill in recentMessages | exit 0 (allow) | Skill was used, allow |
| H24 | Bash `pandoc resume.md -o resume.pdf` without context | exit 0 (allow) | Pandoc isn't skill-gated |

### pre-lsp-first.ts (KNOWN BROKEN)

| # | Input | Expected | Actual (predicted) | Description |
|---|-------|----------|-------------------|-------------|
| H25 | Edit with infrastructure config patterns | exit 2 (block) | exit 0 (pass-through) | Hook reads wrong format -- will pass everything |
| H26 | Edit with normal code | exit 0 (allow) | exit 0 (allow) | Correct by accident |

### pre-autopilot-check.ts (LAW 13)

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H27 | 7 consecutive Write calls without user message | exit 2 (block) | Should detect autopilot at 6 |
| H28 | 3 Write calls then a user message then 2 more | exit 0 (allow) | User interaction resets counter |
| H29 | Same input but CLAUDE_CODE_AGENT is set | exit 0 (allow) | Subagents bypass this check |

### pre-bash-no-heredoc.ts

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H30 | Bash with `cat << EOF > file.txt\nlong content...EOF` | exit 2 (block) | File-writing heredoc blocked |
| H31 | Bash with short `git commit -m "$(cat <<'EOF'...EOF)"` | exit 0 (allow) | Short git commit heredoc allowed |

### enforce-skill-usage.ts

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H32 | Glob on qmd-indexed collection path | exit 2 (block) | Should redirect to qmd |
| H33 | Glob on ~/.config/pai/Skills/ | exit 0 (allow) | Not indexed, should pass |
| H34 | Read on qmd-indexed path | exit 0 (allow + warn) | Read gets warning, not block |

### pre-qmd-first.ts (LAW 10)

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H35 | Grep for short pattern without prior qmd use | exit 2 (block) | Should require qmd first |
| H36 | Grep for 45-char specific pattern | exit 0 (allow) | Long patterns bypass (KNOWN WEAKNESS) |
| H37 | Glob for `**/*.ts` without prior qmd use | exit 2 (block) | Exploratory glob blocked |
| H38 | Grep with qmd tool in last 15 messages | exit 0 (allow) | qmd was used, allow search |

### security-validator.ts

| # | Input | Expected | Description |
|---|-------|----------|-------------|
| H39 | Bash `rm -rf /` | exit 2 (block) | Catastrophic deletion blocked |
| H40 | Bash `curl https://api.example.com/data` | exit 0 (allow with ask) | Curl triggers ask, but exits 0 (KNOWN WEAKNESS) |
| H41 | Bash reverse shell pattern | exit 2 (block) | Reverse shell blocked |

---

## Skill Trigger Tests

Each test: match a simulated user request against skill triggers.

### Credential/Secret Requests

| # | User Request | Expected Skill | Description |
|---|-------------|----------------|-------------|
| S01 | "I need the API key for Discord" | vaultwarden | Credential request |
| S02 | "what's the password for the database" | vaultwarden | Password request |
| S03 | "get me the n8n credentials" | vaultwarden | Service credential |
| S04 | "look up the token for LiteLLM" | vaultwarden | Token request |

### Session Management

| # | User Request | Expected Skill | Description |
|---|-------------|----------------|-------------|
| S05 | "let's wrap up for the night" | session-wrap | Natural language wrap |
| S06 | "wrap this session" | session-wrap | Direct trigger |
| S07 | "where did we leave off" | session-start | Session recovery |
| S08 | "pick up where we left off" | session-start | Natural language start |

### Infrastructure

| # | User Request | Expected Skill | Description |
|---|-------------|----------------|-------------|
| S09 | "deploy a new container for redis" | deploy-service | Deployment request |
| S10 | "check the VMs on proxmox" | proxmox | Proxmox query |
| S11 | "restart the n8n service" | n8n | n8n service ops |
| S12 | "what containers are running" | proxmox | Container listing |

### Image Generation

| # | User Request | Expected Skill | Description |
|---|-------------|----------------|-------------|
| S13 | "generate a thumbnail for the blog post" | nano-banana | Image gen request |
| S14 | "create an icon for the app" | nano-banana | Icon request |
| S15 | "make an infographic about the architecture" | visual-content-enforcer | Infographic -> VCE first |

### Todo Management

| # | User Request | Expected Skill | Description |
|---|-------------|----------------|-------------|
| S16 | "add a todo for fixing the auth bug" | add-todo | Add todo |
| S17 | "what's on my todo list" | check-todos | Check todos |
| S18 | "mark the deploy task as done" | update-todo | Update todo |

### Git/Code Operations

| # | User Request | Expected Skill | Description |
|---|-------------|----------------|-------------|
| S19 | "commit these changes" | Git | Git commit |
| S20 | "create a PR for this branch" | Git | PR creation |
| S21 | "summarize the changes on this branch" | Git | Git diff analysis |

### Knowledge/Research

| # | User Request | Expected Skill | Description |
|---|-------------|----------------|-------------|
| S22 | "search my brain for auth patterns" | brain | OB query |
| S23 | "research best practices for caching" | Research | Research request |
| S24 | "process this YouTube video" | Fabric | YouTube/fabric |

### Overlap Tests (should trigger exactly ONE skill, not multiple)

| # | User Request | Expected Winner | Known Competitors | Description |
|---|-------------|----------------|-------------------|-------------|
| S25 | "create a new skill for X" | skill-add | CreateSkill, system-createskill, create-skill-dm | 4-way skill creation overlap |
| S26 | "build a skill that does Y" | skill-add | CreateSkill, system-createskill, create-skill-dm | 4-way overlap variant |
| S27 | "open a browser and check the dashboard" | browser | gsd-browser | browser should delegate to gsd |
| S28 | "check VMs on proxmox" | proxmox | proxmox-mcp | Two proxmox skills with same triggers |
| S29 | "get the API key from vaultwarden" | vaultwarden | vaultwarden-secrets | vaultwarden is preferred over raw MCP |
| S30 | "scrape this webpage" | browser | brightdata, gsd-browser | 3-way browser/scrape overlap |

### Negative Tests (should NOT trigger any specific skill)

| # | User Request | Expected | Description |
|---|-------------|----------|-------------|
| S31 | "explain this function to me" | No skill (general) | Code explanation is general |
| S32 | "fix the bug on line 42" | No skill (general) | Bug fix is general |
| S33 | "what does this error mean" | No skill (or Debug) | Error interpretation |

### Missing Skill Definition Tests

| # | Directory | Expected | Description |
|---|-----------|----------|-------------|
| S34 | gh-review | SKILL.md should exist | Directory exists but no SKILL.md |
| S35 | skippy | SKILL.md should exist | Directory exists but no SKILL.md |

---

## Skill Quality Tests

Evaluate each skill's SKILL.md content against quality criteria.

### Quality Criteria (Binary -- agent-judge)

| # | Criterion | What It Checks |
|---|-----------|----------------|
| Q1 | Does the skill have clear, numbered steps in the SKILL.md? | Actionability |
| Q2 | Can an agent execute the core workflow without reading references? | Self-containedness |
| Q3 | Are all referenced files/paths still valid? | Currency |
| Q4 | Would using this skill produce better results than doing it manually? | Value-add |
| Q5 | Is the trigger description specific enough to avoid false positives? | Trigger precision |
| Q6 | Is the trigger description broad enough to catch natural language variants? | Trigger recall |

### Priority Skills to Test

Focus on the skills that get skipped most often (from user feedback):

1. vaultwarden -- credentials
2. session-wrap -- session management
3. deploy-service -- container deployment
4. n8n -- workflow management
5. add-todo / check-todos / update-todo -- todo management
6. brain -- OB queries
7. Git -- commit/PR
8. nano-banana -- image generation
9. Fabric -- content processing
10. proxmox -- cluster management
