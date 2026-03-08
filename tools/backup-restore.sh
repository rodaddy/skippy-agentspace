#!/usr/bin/env bash
set -euo pipefail

# backup-restore.sh -- Snapshot and restore ~/.claude/ before testing
#
# Usage:
#   backup-restore.sh backup              Create timestamped snapshot
#   backup-restore.sh backup --name foo   Create named snapshot
#   backup-restore.sh restore             Restore most recent snapshot
#   backup-restore.sh restore --name foo  Restore named snapshot
#   backup-restore.sh list                List available snapshots
#   backup-restore.sh diff                Compare current state to most recent snapshot

BACKUP_BASE="${SKIPPY_BACKUP_DIR:-$HOME/.cache/skippy-backups}"
CLAUDE_DIR="$HOME/.claude"

backup() {
    local name="${1:-$(date +%Y%m%d-%H%M%S)}"
    local dest="$BACKUP_BASE/$name"

    if [[ -d "$dest" ]]; then
        echo "ERROR: Snapshot '$name' already exists. Use a different name."
        exit 1
    fi

    mkdir -p "$dest"

    # Snapshot skills (symlink targets, not contents)
    echo "=== Backing up skills ==="
    if [[ -d "$CLAUDE_DIR/skills" ]]; then
        mkdir -p "$dest/skills"
        for item in "$CLAUDE_DIR/skills"/*/; do
            item="${item%/}"
            local basename
            basename="$(basename "$item")"
            if [[ -L "$item" ]]; then
                # Record symlink target
                readlink "$item" > "$dest/skills/$basename.link"
                echo "  SYMLINK: $basename -> $(readlink "$item")"
            elif [[ -d "$item" ]]; then
                # Copy real directories
                cp -R "$item" "$dest/skills/$basename"
                echo "  DIR: $basename (copied)"
            fi
        done
    fi

    # Snapshot commands
    if [[ -d "$CLAUDE_DIR/commands" ]]; then
        mkdir -p "$dest/commands"
        for item in "$CLAUDE_DIR/commands"/*/; do
            item="${item%/}"
            local basename
            basename="$(basename "$item")"
            if [[ -L "$item" ]]; then
                readlink "$item" > "$dest/commands/$basename.link"
                echo "  SYMLINK: $basename -> $(readlink "$item")"
            elif [[ -d "$item" ]]; then
                cp -R "$item" "$dest/commands/$basename"
                echo "  DIR: $basename (copied)"
            fi
        done
        # Also backup .md command files
        for item in "$CLAUDE_DIR/commands"/*.md; do
            [[ -f "$item" ]] || continue
            local basename
            basename="$(basename "$item")"
            if [[ -L "$item" ]]; then
                readlink "$item" > "$dest/commands/$basename.link"
            else
                cp "$item" "$dest/commands/$basename"
            fi
        done
    fi

    # Snapshot settings.json
    if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
        cp "$CLAUDE_DIR/settings.json" "$dest/settings.json"
        echo "  SETTINGS: settings.json (copied)"
    fi

    # Record metadata
    cat > "$dest/MANIFEST.md" << MANIFEST
# Backup: $name
Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Skills: $(ls "$dest/skills/" 2>/dev/null | wc -l | tr -d ' ')
Commands: $(ls "$dest/commands/" 2>/dev/null | wc -l | tr -d ' ')
Settings: $(test -f "$dest/settings.json" && echo "yes" || echo "no")
MANIFEST

    echo ""
    echo "=== Snapshot saved: $dest ==="
    echo "  Skills: $(ls "$dest/skills/" 2>/dev/null | wc -l | tr -d ' ')"
    echo "  Commands: $(ls "$dest/commands/" 2>/dev/null | wc -l | tr -d ' ')"
    echo ""
    echo "Restore with: bash tools/backup-restore.sh restore --name $name"
}

restore() {
    local name="$1"
    local src="$BACKUP_BASE/$name"

    if [[ ! -d "$src" ]]; then
        echo "ERROR: Snapshot '$name' not found at $src"
        echo "Available snapshots:"
        list
        exit 1
    fi

    echo "=== Restoring from: $src ==="
    cat "$src/MANIFEST.md" 2>/dev/null
    echo ""

    # Restore skills
    if [[ -d "$src/skills" ]]; then
        mkdir -p "$CLAUDE_DIR/skills"
        for item in "$src/skills"/*; do
            local basename
            basename="$(basename "$item")"
            if [[ "$basename" == *.link ]]; then
                local skill_name="${basename%.link}"
                local target
                target="$(cat "$item")"
                # Validate target: must exist, be a directory, and not contain path traversal
                if [[ -e "$CLAUDE_DIR/skills/$skill_name" ]]; then
                    echo "  SKIP (exists): $skill_name"
                elif [[ "$target" == *..* ]]; then
                    echo "  WARN: refusing path traversal target for $skill_name: $target"
                elif [[ -d "$target" ]]; then
                    ln -s "$target" "$CLAUDE_DIR/skills/$skill_name"
                    echo "  RESTORED: $skill_name -> $target"
                else
                    echo "  WARN: target missing or not a directory for $skill_name: $target"
                fi
            elif [[ -d "$item" ]]; then
                if [[ -e "$CLAUDE_DIR/skills/$basename" ]]; then
                    echo "  SKIP (exists): $basename"
                else
                    cp -R "$item" "$CLAUDE_DIR/skills/$basename"
                    echo "  RESTORED (dir): $basename"
                fi
            fi
        done
    fi

    # Restore commands
    if [[ -d "$src/commands" ]]; then
        mkdir -p "$CLAUDE_DIR/commands"
        for item in "$src/commands"/*; do
            local basename
            basename="$(basename "$item")"
            if [[ "$basename" == *.link ]]; then
                local cmd_name="${basename%.link}"
                local target
                target="$(cat "$item")"
                # Validate target: must exist and not contain path traversal
                if [[ -e "$CLAUDE_DIR/commands/$cmd_name" ]]; then
                    echo "  SKIP (exists): $cmd_name"
                elif [[ "$target" == *..* ]]; then
                    echo "  WARN: refusing path traversal target for $cmd_name: $target"
                elif [[ -e "$target" ]]; then
                    ln -s "$target" "$CLAUDE_DIR/commands/$cmd_name"
                    echo "  RESTORED: $cmd_name -> $target"
                else
                    echo "  WARN: target missing for $cmd_name: $target"
                fi
            elif [[ -f "$item" ]]; then
                if [[ -e "$CLAUDE_DIR/commands/$basename" ]]; then
                    echo "  SKIP (exists): $basename"
                else
                    cp "$item" "$CLAUDE_DIR/commands/$basename"
                    echo "  RESTORED: $basename"
                fi
            fi
        done
    fi

    # Restore settings.json (only if current is missing)
    if [[ -f "$src/settings.json" ]] && [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
        cp "$src/settings.json" "$CLAUDE_DIR/settings.json"
        echo "  RESTORED: settings.json"
    fi

    echo ""
    echo "=== Restore complete ==="
    echo "Current skills: $(ls "$CLAUDE_DIR/skills/" 2>/dev/null | wc -l | tr -d ' ')"
}

list() {
    if [[ ! -d "$BACKUP_BASE" ]]; then
        echo "No backups found at $BACKUP_BASE"
        return
    fi
    echo "=== Available snapshots ==="
    for snap in "$BACKUP_BASE"/*/; do
        snap="${snap%/}"
        local name
        name="$(basename "$snap")"
        local skills
        skills="$(find "$snap/skills/" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
        local date
        date="$(grep "Created:" "$snap/MANIFEST.md" 2>/dev/null | cut -d' ' -f2)"
        echo "  $name  ($skills skills, $date)"
    done
}

diff_snapshot() {
    local latest
    latest="$(ls -td "$BACKUP_BASE"/*/ 2>/dev/null | head -1)"
    latest="${latest%/}"
    if [[ -z "$latest" ]]; then
        echo "No snapshots to compare against."
        exit 1
    fi
    echo "=== Comparing current to: $(basename "$latest") ==="
    echo ""
    echo "--- Skills in snapshot but not current ---"
    for item in "$latest/skills"/*; do
        local basename
        basename="$(basename "$item")"
        basename="${basename%.link}"
        if [[ ! -e "$CLAUDE_DIR/skills/$basename" ]]; then
            echo "  MISSING: $basename"
        fi
    done
    echo ""
    echo "--- Skills in current but not snapshot ---"
    for item in "$CLAUDE_DIR/skills"/*/; do
        item="${item%/}"
        local basename
        basename="$(basename "$item")"
        if [[ ! -e "$latest/skills/$basename.link" ]] && [[ ! -d "$latest/skills/$basename" ]]; then
            echo "  NEW: $basename"
        fi
    done
}

# --- Argument parsing ---
ACTION="${1:-}"
NAME=""

shift 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) NAME="$2"; shift 2 ;;
        *) NAME="$1"; shift ;;
    esac
done

case "$ACTION" in
    backup)  backup "${NAME:-$(date +%Y%m%d-%H%M%S)}" ;;
    restore)
        if [[ -z "$NAME" ]]; then
            NAME="$(ls -td "$BACKUP_BASE"/*/ 2>/dev/null | head -1)"
            NAME="$(basename "${NAME%/}")"
        fi
        restore "$NAME"
        ;;
    list)    list ;;
    diff)    diff_snapshot ;;
    *)
        echo "Usage: backup-restore.sh {backup|restore|list|diff} [--name NAME]"
        echo ""
        echo "  backup              Create timestamped snapshot of ~/.claude/"
        echo "  backup --name foo   Create named snapshot"
        echo "  restore             Restore most recent snapshot"
        echo "  restore --name foo  Restore named snapshot"
        echo "  list                List available snapshots"
        echo "  diff                Compare current state to most recent snapshot"
        ;;
esac
