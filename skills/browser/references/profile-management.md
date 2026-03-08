# Chrome Profile Management

Persistent profiles store login cookies for automated browsing.

## Profile Location

`~/.agent-browser/profiles/<name>/`

## Adding a New Site Login

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --user-data-dir="$HOME/.agent-browser/profiles/<site>" \
  --use-mock-keychain \
  --password-store=basic \
  --no-first-run \
  --disable-blink-features=AutomationControlled \
  https://<site>/login
```

**CRITICAL flags:**
- `--use-mock-keychain` and `--password-store=basic` -- without them, Playwright can't read the cookies
- `--disable-blink-features=AutomationControlled` -- prevents automation detection

## Troubleshooting

**Profile lock errors:**
```bash
rm -f ~/.agent-browser/profiles/<name>/SingletonLock
```

**Only one instance per profile** -- close existing sessions before reusing a profile.

## Tips

- Name profiles by site: `medium`, `grafana`, `n8n`
- Log in manually once, then automation reuses the cookies
- Profiles persist across sessions -- no need to re-login
