# Brain Namespace Guide

## Host Detection

| Hostname Pattern | Type | Default Namespace | Example |
|-----------------|------|-------------------|---------|
| `cc-*` | LXC container | `collab` | cc-dev, cc-alice, cc-bob |
| `*.local` | Personal machine | `<caller_identity>` | my-mac.local, dev-laptop.local |
| Other | Unknown | `<caller_identity>` | |

## Known Hosts

| Hostname | Owner | Location |
|----------|-------|----------|
| `my-mac.local` | User | Local desktop |
| `dev-laptop.local` | User/Skippy | Laptop |
| `cc-dev` | Dev (collab) | LXC container |
| `cc-alice` | Alice | LXC container |
| `cc-bob` | Bob | LXC container |

## Directory-Based Override (Personal Machines Only)

On `*.local` hosts, the working directory overrides the default:

| Directory Pattern | Namespace | Why |
|-------------------|-----------|-----|
| `*/team-project*` or `*/Team-Project*` | `collab` | Shared project work is collaborative |
| Everything else | `<caller_identity>` | Personal by default |

LXC boxes do NOT use directory detection -- they default to `collab` regardless of cwd.

## Intent Keywords

These phrases override all host/directory detection:

### Personal Override
- "my brain", "my ob"
- "personal", "private"
- "save to my ..."
- "this is personal"
- "keep this private"

Result: `namespace = <caller_identity>`

### Collab Override
- "collab", "shared", "team"
- "team-project", "push to collab"
- "this is for the team"

Result: `namespace = "collab"`

## Resolution Order

1. **Explicit intent** -- user says "personal" or "collab" -> use that
2. **Host type** -- `cc-*` -> collab default; `*.local` -> identity default
3. **Directory** -- only on personal machines; `king*` -> collab
4. **Fallback** -- `<caller_identity>`

## Examples

### User on local Mac, in ~/Development/team-project-api
```
Host: my-mac.local (personal machine)
CWD: team-project-api (matches team-project*)
-> namespace: "collab"
```

### User on local Mac, in ~/Development/side-project
```
Host: my-mac.local (personal machine)
CWD: side-project (no team-project match)
-> namespace: "user"
```

### User on local Mac, in ~/Development/side-project, says "push this to collab"
```
Host: my-mac.local (personal machine)
CWD: side-project (no team-project match)
Intent: "collab" override
-> namespace: "collab" (intent wins)
```

### Alice on cc-alice LXC, working on anything
```
Host: cc-alice (LXC)
-> namespace: "collab"
```

### Alice on cc-alice LXC, says "save this to my brain"
```
Host: cc-alice (LXC)
Intent: "my brain" -> personal override
-> namespace: "alice" (intent wins)
```

### Skippy on dev-laptop.local, in ~/Development/open-brain
```
Host: dev-laptop.local (personal machine)
CWD: open-brain (no team-project match)
Caller: skippy
-> namespace: "skippy"
```

### Skippy on dev-laptop.local, says "this is for the team"
```
Host: dev-laptop.local (personal machine)
Intent: "team" -> collab override
-> namespace: "collab" (intent wins)
```
