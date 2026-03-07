# LAW 11: No Secrets in Git

**Enforcement:** ggshield pre-commit + pre-push hooks
**Severity:** MANDATORY

## Rule

Never commit API keys, tokens, passwords, SSH keys, OAuth secrets, or encryption keys.

## Why

Secrets in git history are permanent. Even after removal, they persist in reflog and clones. Automated scanners harvest exposed credentials within minutes of a public push. Prevention is orders of magnitude cheaper than incident response.

## Enforcement Details

- ggshield pre-commit hook scans staged changes for secret patterns
- ggshield pre-push hook scans before push as a second layer
- Detects: API keys, tokens, passwords, private keys, connection strings, OAuth secrets

## Rules

- Use .env files (gitignored) for project secrets
- Use a secrets manager (e.g., vaultwarden) for shared credentials
- MCP config files with inline tokens WILL get flagged -- use .env instead
- Before first push of ANY repo: run a full repo scan to catch pre-existing secrets

## Incident Response

If a secret is committed:
1. **Revoke immediately** -- the secret is compromised
2. **Rewrite history** with `git filter-repo` to remove the secret
3. **Force push** -- note that `filter-repo` removes the origin remote by design; re-add after
4. **Rotate** -- generate a new secret and update all consumers

## Exceptions

- None. There is never a valid reason to commit real secrets to git.
