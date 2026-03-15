---
name: gh-review:setup
description: Set up Claude Code PR review workflow with self-hosted runner for a GitHub repo
argument-hint: "<owner/repo>"
---

<objective>
Register a self-hosted runner on the shared review LXC and create a Claude Code review workflow for the specified repo. After setup, every PR to the repo gets an automated Claude Code review.
</objective>

<context>
Repo: $ARGUMENTS (required -- e.g., "rodaddy/my-project")

Runner LXC: 106 (gh-runner) at 10.71.1.114, SSH as root
Runner user: runner
Runner home: /home/runner/
LiteLLM proxy: http://10.71.20.53:4000
Vaultwarden secret: "LiteLLM" (via get_secret, returns text field -- NOT get_credential)
</context>

<process>

## Step 1: Validate Inputs

Parse repo from $ARGUMENTS. Must be `owner/repo` format.

```bash
REPO="$ARGUMENTS"
REPO_NAME=$(echo "$REPO" | cut -d'/' -f2)
```

Verify repo exists:
```bash
gh repo view "$REPO" --json name --jq '.name'
```

If it fails, stop and report.

## Step 2: Check Runner LXC

Verify SSH access and required tools:
```bash
ssh -o ConnectTimeout=5 root@10.71.1.114 "
  echo 'SSH: OK'
  su - runner -c 'export PATH=/usr/local/bin:/home/runner/.local/bin:/home/runner/.bun/bin:\$PATH && node --version && claude --version && bun --version'
"
```

All three must be present. If any missing, report what needs installing and stop.

## Step 3: Check for Existing Runner

Check if a runner is already registered for this repo:
```bash
gh api repos/$REPO/actions/runners --jq '.runners[] | .name + " (" + .status + ")"'
```

If a runner already exists and is online, skip to Step 6 (workflow creation). If it exists but is offline, report and ask whether to re-register.

## Step 4: Register Runner

Get registration token and set up a new runner instance:
```bash
TOKEN=$(gh api repos/$REPO/actions/runners/registration-token -X POST --jq '.token')
RUNNER_DIR="/home/runner/actions-runner-${REPO_NAME}"
RUNNER_NAME="gh-runner-${REPO_NAME}"
RUNNER_LABEL="${REPO_NAME}"

ssh -o ConnectTimeout=10 root@10.71.1.114 "
  su - runner -c '
    mkdir -p $RUNNER_DIR
    cd $RUNNER_DIR
    # Download latest runner release (check version at https://github.com/actions/runner/releases)
    RUNNER_VERSION=\$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep tag_name | cut -d\\\"\\\" -f4 | sed s/v//)
    curl -fsSL https://github.com/actions/runner/releases/download/v\${RUNNER_VERSION}/actions-runner-linux-x64-\${RUNNER_VERSION}.tar.gz -o /tmp/runner.tar.gz
    tar xzf /tmp/runner.tar.gz
    ./config.sh --url https://github.com/$REPO --token $TOKEN --name $RUNNER_NAME --labels self-hosted,Linux,X64,$RUNNER_LABEL --unattended
  '
"
```

If config.sh fails (token expired, repo not found), report the error.

## Step 5: Start Runner Service

Install and start as systemd service, configure PATH:
```bash
ssh -o ConnectTimeout=10 root@10.71.1.114 "
  echo 'PATH=/home/runner/.local/bin:/home/runner/.bun/bin:/usr/local/bin:/usr/bin:/bin' >> $RUNNER_DIR/.env
  echo 'LANG=C' >> $RUNNER_DIR/.env
  cd $RUNNER_DIR
  ./svc.sh install runner
  ./svc.sh start
  ./svc.sh status
"
```

Verify runner appears on GitHub:
```bash
gh api repos/$REPO/actions/runners --jq '.runners[] | .name + " (" + .status + ")"'
```

Must show online. If not, wait 10 seconds and retry once.

## Step 6: Set GitHub Secret

Get LiteLLM API key from vaultwarden and set as repo secret:
```bash
LITELLM_KEY=$(mcp2cli vaultwarden-secrets get_secret --params '{"name": "LiteLLM"}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('text',''))")
gh secret set LITELLM_API_KEY --body "$LITELLM_KEY" --repo "$REPO"
```

Check if secret already exists first:
```bash
gh api repos/$REPO/actions/secrets --jq '.secrets[].name' | grep LITELLM_API_KEY
```

If it exists, skip (don't overwrite).

## Step 7: Create Workflow File

Check if the repo is the current working directory. If yes, create the file locally. If not, use the GitHub API.

**If local repo:**
```bash
mkdir -p .github/workflows
```

Write `.github/workflows/claude-code-review.yml` with the Write tool.

**If remote repo:**
Use `gh api` to create the file via the Contents API.

**Workflow template:**
```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize, reopened]
  issue_comment:
    types: [created]

concurrency:
  group: claude-review-${{ github.event.pull_request.number || github.event.issue.number }}
  cancel-in-progress: true

env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"

jobs:
  claude-review:
    if: |
      (github.event_name == 'pull_request') ||
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude'))
    runs-on: [self-hosted, RUNNER_LABEL]
    permissions:
      contents: read
      pull-requests: write
      issues: write
    env:
      ANTHROPIC_BASE_URL: http://10.71.20.53:4000
      ANTHROPIC_API_KEY: ${{ secrets.LITELLM_API_KEY }}
      ANTHROPIC_MODEL: opus
      ANTHROPIC_DEFAULT_SONNET_MODEL: sonnet
      ANTHROPIC_DEFAULT_OPUS_MODEL: opus
      ANTHROPIC_DEFAULT_HAIKU_MODEL: haiku
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Run Claude Code Review
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.LITELLM_API_KEY }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
          prompt: |
            Review this PR. Focus on:
            1. Bugs and logic errors
            2. Security issues (OWASP top 10)
            3. Performance concerns
            4. Missing error handling at system boundaries
            5. If you find a recurring mistake pattern, suggest a CLAUDE.md correction
          path_to_bun_executable: /usr/local/bin/bun
          path_to_claude_code_executable: /home/runner/.local/bin/claude
          show_full_output: true
```

Replace `RUNNER_LABEL` with the actual label from Step 4.

**If the repo has a CLAUDE.md**, read it and customize the review prompt with project-specific conventions (e.g., shell shebangs, file size limits, stack preferences).

## Step 8: Commit and Push (if local)

If the workflow was created locally:
```bash
git add .github/workflows/claude-code-review.yml
git commit -m "feat: add Claude Code review workflow with self-hosted runner"
git push
```

**IMPORTANT:** New workflow files only activate from the default branch (main). If you're on a feature branch, the workflow won't trigger until merged. Options:
- Merge the PR that adds the workflow first (reviews start on subsequent PRs)
- Cherry-pick just the workflow file to main to activate immediately

## Step 9: Verify

Confirm everything is wired:
```bash
# Runner online
gh api repos/$REPO/actions/runners --jq '.runners[] | .name + " (" + .status + ")"'

# Secret set
gh api repos/$REPO/actions/secrets --jq '.secrets[].name' | grep LITELLM_API_KEY

# Workflow exists
gh api repos/$REPO/actions/workflows --jq '.workflows[] | .name + " (" + .state + ")"'
```

## Step 10: Report

```
## gh-review Setup Complete

**Repo:** $REPO
**Runner:** $RUNNER_NAME (online on LXC 106)
**Label:** self-hosted, Linux, X64, $RUNNER_LABEL
**Secret:** LITELLM_API_KEY (set)
**Workflow:** .github/workflows/claude-code-review.yml

Next PR to this repo will trigger a Claude Code review automatically.
To test: create a small PR and watch the Checks tab.
```

</process>
