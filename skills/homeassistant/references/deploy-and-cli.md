<!-- Extracted from SKILL.md -- load on demand -->

# Deploy Workflow & CLI Reference

## Repository Structure

Two separate repos:

| Repo | Path | Purpose |
|------|------|---------|
| **Dev repo** | `<DEV_DIR>/HomeAssistant/` | Python CLI tools, scripts, config templates |
| **Deploy repo** | `<DEV_DIR>/home-assistant-config/` | Live HA config, synced to GitHub |

Deploy repo is connected to HA via Git Pull add-on (auto-pull + auto-restart).

## Config Layout (Dev Repo)

```
config/
  configuration.yaml        # Core config, packages loader, person definitions
  automations.yaml           # All automations (consolidated single file)
  scripts.yaml               # All scripts
  customize.yaml             # Entity customization
  packages/
    core_integrations.yaml   # logger, recorder, history, logbook
    input_helpers.yaml       # input_boolean, input_select, etc.
    template_sensors.yaml    # Template sensors
  scenes/
    office_scenes.yaml       # 9 scenes
    homekit_migration.yaml   # Siri-accessible scenes
  dashboards/
    control_center.yaml      # Main dashboard (sidebar)
    scenes_control.yaml
    system_monitoring.yaml
    automations_manager.yaml
  blueprints/
```

## Deploy Script

**Location:** `scripts/deploy.sh`

```bash
# Full deploy: sync + commit + push
./scripts/deploy.sh "commit message"

# Sync only (no commit)
./scripts/deploy.sh --sync-only
```

**What it syncs:** configuration.yaml, automations.yaml, scripts.yaml, customize.yaml, packages/, scenes/, dashboards/, blueprints/

**Flow:**
1. Syncs `config/` -> deploy repo
2. Creates temp branch on deploy repo
3. Commits with provided message
4. Merges to main
5. Pushes to GitHub
6. Git Pull add-on auto-pulls and restarts HA

## Validation

```bash
# Quick validation via HA REST API
./scripts/validate.sh

# Or via CLI tool
cd <DEV_DIR>/HomeAssistant
uv run ha-manager validate
uv run ha-manager validate config    # With saved connection
```

## ha-manager CLI Commands

### Validation
```bash
uv run ha-manager validate                              # Validate via REST API
uv run ha-manager validate setup --url <url> --token <token>  # Setup connection
uv run ha-manager validate config                        # Use saved connection
```

### Entity Management
```bash
uv run ha-manager update entities --live-context <json>  # Update from live HA
uv run ha-manager read entities                          # Read local entities
```

### Diff
```bash
uv run ha-manager diff            # Summary of all changes
uv run ha-manager diff status     # Git status
uv run ha-manager diff staged     # Staged changes
uv run ha-manager diff unstaged   # Unstaged changes
uv run ha-manager diff deploy     # Preview deployment changes
uv run ha-manager diff all        # All changes vs last commit
```

### Scene Creation
```bash
uv run ha-manager create templates                                    # List all templates
uv run ha-manager create templates --type scenes                      # Scene templates only
uv run ha-manager create scene "Name"                                 # Basic scene
uv run ha-manager create scene "Name" --room "Office"                 # With room
uv run ha-manager create scene "Name" --template evening-lights --room "Office"  # From template
```

**Available templates:** evening-lights, morning-bright, movie-time, motion-lights

## Git Pull Add-on

- Monitors GitHub repo: `https://github.com/<GITHUB_USER>/home-assistant-config`
- Branch: `main`
- Auto-restart: enabled
- Check status: HA UI > Settings > Devices & Services > Git Pull

## Recorder Configuration

**Tracked domains:** light, switch, sensor, binary_sensor, person, automation, scene, media_player, vacuum, climate, weather, input_boolean, input_select

**Excluded:** firmware/signal/linkquality sensors, update buttons, numbers, selects, events

**Settings:** 7-day retention, 1-second commit interval
