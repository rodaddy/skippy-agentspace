/**
 * JSON merge/removal backend for PAI hook installer.
 *
 * Called by install-hooks.sh and uninstall-hooks.sh via:
 *   bun run merge.ts <action> <settings-path> <manifest-path> <hooks-dir>
 *
 * Actions:
 *   merge  - Add PAI hooks to settings.json (idempotent)
 *   remove - Remove only PAI hooks from settings.json (double-check strategy)
 *
 * Exports mergeHooks and removeHooks for programmatic use.
 */

import { readFileSync, writeFileSync, realpathSync } from "fs";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ManifestHook {
  id: string;
  law: number;
  name: string;
  description?: string;
  event: string;
  matcher: string | null;
  script: string;
  blocking: boolean;
}

interface Manifest {
  version: string;
  description: string;
  path_prefix: string;
  identifier: string;
  hooks: ManifestHook[];
}

interface SettingsHookEntry {
  type: string;
  command: string;
  timeout?: number;
}

interface MatcherGroup {
  matcher: string;
  hooks: SettingsHookEntry[];
}

interface Settings {
  hooks?: Record<string, MatcherGroup[]>;
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Merge: Add PAI hooks to settings.json
// ---------------------------------------------------------------------------

export function mergeHooks(
  settings: Settings,
  manifest: Manifest,
  hooksDir: string,
): { settings: Settings; added: number; skipped: number } {
  if (!settings.hooks) {
    settings.hooks = {};
  }

  let added = 0;
  let skipped = 0;

  // Group manifest hooks by event+matcher for efficiency
  const groups = new Map<string, ManifestHook[]>();
  for (const hook of manifest.hooks) {
    const key = `${hook.event}::${hook.matcher ?? ""}`;
    const existing = groups.get(key);
    if (existing) {
      existing.push(hook);
    } else {
      groups.set(key, [hook]);
    }
  }

  // Collect all existing command strings for dedup
  const existingCommands = new Set<string>();
  for (const eventGroups of Object.values(settings.hooks)) {
    for (const group of eventGroups) {
      for (const hookEntry of group.hooks) {
        existingCommands.add(hookEntry.command);
      }
    }
  }

  for (const [key, hooks] of groups) {
    const [event, matcher] = key.split("::");
    if (!settings.hooks[event]) {
      settings.hooks[event] = [];
    }

    const newEntries: SettingsHookEntry[] = [];
    for (const hook of hooks) {
      // Resolve to absolute path, following symlinks
      let scriptPath: string;
      try {
        scriptPath = realpathSync(`${hooksDir}/${hook.script}`);
      } catch {
        // If realpath fails (file doesn't exist yet?), use the joined path
        scriptPath = `${hooksDir}/${hook.script}`;
      }
      const command = `bun run ${scriptPath}`;

      if (existingCommands.has(command)) {
        skipped++;
        continue;
      }

      newEntries.push({ type: "command", command });
      existingCommands.add(command);
      added++;
    }

    if (newEntries.length > 0) {
      const matcherGroup: MatcherGroup = {
        matcher: matcher || "*",
        hooks: newEntries,
      };
      settings.hooks[event].push(matcherGroup);
    }
  }

  return { settings, added, skipped };
}

// ---------------------------------------------------------------------------
// Remove: Remove only PAI hooks from settings.json (double-check strategy)
// ---------------------------------------------------------------------------

export function removeHooks(
  settings: Settings,
  manifest: Manifest,
): { settings: Settings; removed: number } {
  if (!settings.hooks) {
    return { settings, removed: 0 };
  }

  const identifier = manifest.identifier;

  // Build set of manifest script basenames for double-check
  const manifestScripts = new Set(manifest.hooks.map((h) => h.script));

  let removed = 0;

  for (const event of Object.keys(settings.hooks)) {
    const groups = settings.hooks[event];
    const filteredGroups: MatcherGroup[] = [];

    for (const group of groups) {
      const filteredHooks = group.hooks.filter((entry) => {
        // Check 1: Command contains the identifier path
        if (!entry.command.includes(identifier)) {
          return true; // keep -- not a PAI hook
        }

        // Check 2: Command matches a script in manifest
        const matchesManifest = manifest.hooks.some((mh) =>
          entry.command.endsWith(`/${mh.script}`) ||
          entry.command.includes(`/${mh.script}`)
        );

        if (matchesManifest) {
          removed++;
          return false; // remove -- passes both checks
        }

        return true; // keep -- has identifier but not in manifest (safety)
      });

      if (filteredHooks.length > 0) {
        filteredGroups.push({ ...group, hooks: filteredHooks });
      }
      // If hooks array is empty, drop the entire matcher group
    }

    if (filteredGroups.length > 0) {
      settings.hooks[event] = filteredGroups;
    } else {
      delete settings.hooks[event];
    }
  }

  // Clean up empty hooks object
  if (Object.keys(settings.hooks).length === 0) {
    delete settings.hooks;
    settings.hooks = {};
  }

  return { settings, removed };
}

// ---------------------------------------------------------------------------
// CLI entrypoint
// ---------------------------------------------------------------------------

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 3) {
    console.error(
      "Usage: bun run merge.ts <merge|remove> <settings-path> <manifest-path> [hooks-dir]",
    );
    process.exit(1);
  }

  const [action, settingsPath, manifestPath, hooksDir] = args;

  const settings: Settings = JSON.parse(readFileSync(settingsPath, "utf-8"));
  const manifest: Manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));

  if (action === "merge") {
    if (!hooksDir) {
      console.error("merge action requires hooks-dir argument");
      process.exit(1);
    }
    const result = mergeHooks(settings, manifest, hooksDir);
    writeFileSync(settingsPath, JSON.stringify(result.settings, null, 2) + "\n");
    console.log(`Added ${result.added} hooks, skipped ${result.skipped} (already installed)`);
  } else if (action === "remove") {
    const result = removeHooks(settings, manifest);
    writeFileSync(settingsPath, JSON.stringify(result.settings, null, 2) + "\n");
    console.log(`Removed ${result.removed} hooks`);
  } else {
    console.error(`Unknown action: ${action}. Use 'merge' or 'remove'.`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
