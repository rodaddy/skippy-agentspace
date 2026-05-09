#!/usr/bin/env bun
/**
 * Cleanup Script: Remove Skill-Based MCPs from ~/.claude.json
 *
 * This script removes project-specific MCP configurations from ~/.claude.json
 * since they're now loaded on-demand via PAI skills.
 *
 * Usage:
 *   bun cleanup-claude-mcps.ts           # Perform cleanup (creates backups)
 *   bun cleanup-claude-mcps.ts --dry-run # Show what would be removed (no changes)
 *   bun cleanup-claude-mcps.ts -d        # Short form of --dry-run
 *
 * CAUTION: This directly modifies ~/.claude.json. Backup is created automatically.
 */

import { readFileSync, writeFileSync, copyFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

// Check for dry-run mode
const isDryRun = process.argv.includes("--dry-run") || process.argv.includes("-d");

const CLAUDE_JSON_PATH = join(homedir(), ".claude.json");
const BACKUP_PATH = `${CLAUDE_JSON_PATH}.backup-${new Date().toISOString().split('T')[0]}`;
const PAI_PRIVATE_BACKUP_PATH = join(homedir(), ".config/pai-private/backups", `claude.json.pre-skill-migration-${new Date().toISOString().split('T')[0]}`);

// MCPs to remove (now loaded via skills)
const SKILL_BASED_MCPS = [
  "home-assistant",
  "proxmox",
  "unifi",
  "applescript-automator",
  "enhanced-shortcuts",
  "npx", // desktop-commander
  "desktop-commander",
  "filesystem",
  "Context7",
  "sequential-thinking"
];

// Global MCPs to keep (built-in or frequently used)
const GLOBAL_MCPS = [
  "memory",
  "ide",
  "playwright",
  "claude-historian"
];

async function main() {
  if (isDryRun) {
    console.log("🔍 DRY RUN MODE - No changes will be made\n");
    console.log("═══════════════════════════════════════════════════════════════\n");
  } else {
    console.log("🧹 Cleaning up ~/.claude.json...\n");
  }

  // Step 1: Backup (two locations) - Skip in dry-run mode
  if (!isDryRun) {
    console.log("📋 Creating backups...");
    try {
      // Local backup in same directory
      copyFileSync(CLAUDE_JSON_PATH, BACKUP_PATH);
      console.log(`✅ Local backup: ${BACKUP_PATH}`);

      // Reference backup in pai-private (git-tracked)
      copyFileSync(CLAUDE_JSON_PATH, PAI_PRIVATE_BACKUP_PATH);
      console.log(`✅ Reference backup: ${PAI_PRIVATE_BACKUP_PATH}`);
      console.log("   (This backup is git-tracked in pai-private for restore if needed)\n");
    } catch (error) {
      console.error(`❌ Failed to create backup: ${error}`);
      process.exit(1);
    }
  }

  // Step 2: Read and parse
  console.log("📖 Reading ~/.claude.json...");
  let claudeConfig;
  try {
    const content = readFileSync(CLAUDE_JSON_PATH, "utf8");
    claudeConfig = JSON.parse(content);
    console.log("✅ Parsed successfully\n");
  } catch (error) {
    console.error(`❌ Failed to read/parse: ${error}`);
    process.exit(1);
  }

  // Step 3: Clean up projects
  console.log(`🔧 ${isDryRun ? 'Would remove' : 'Removing'} skill-based MCPs from projects...\n`);
  let totalRemoved = 0;
  let projectsModified = 0;
  const removalDetails: Array<{project: string; mcps: string[]}> = [];

  if (claudeConfig.projects) {
    for (const [projectPath, projectConfig] of Object.entries(claudeConfig.projects)) {
      if (projectConfig.mcpServers) {
        let removedFromProject = 0;
        const mcpsToRemove: string[] = [];

        for (const mcpName of SKILL_BASED_MCPS) {
          if (projectConfig.mcpServers[mcpName]) {
            mcpsToRemove.push(mcpName);
            if (!isDryRun) {
              delete projectConfig.mcpServers[mcpName];
            }
            removedFromProject++;
            totalRemoved++;
          }
        }

        if (removedFromProject > 0) {
          projectsModified++;
          removalDetails.push({ project: projectPath, mcps: mcpsToRemove });
          console.log(`  📁 ${projectPath}:`);
          for (const mcp of mcpsToRemove) {
            console.log(`     ${isDryRun ? '🔹 Would remove' : '❌ Removed'}: ${mcp}`);
          }
          console.log();
        }
      }
    }
  }

  console.log(`${isDryRun ? '📊 Would remove' : '✅ Removed'} ${totalRemoved} MCP config(s) from ${projectsModified} project(s)\n`);

  // Step 4: Show what's left
  console.log("📊 Remaining project MCP configurations:");
  if (claudeConfig.projects) {
    for (const [projectPath, projectConfig] of Object.entries(claudeConfig.projects)) {
      if (projectConfig.mcpServers && Object.keys(projectConfig.mcpServers).length > 0) {
        const mcpNames = Object.keys(projectConfig.mcpServers);
        console.log(`  📁 ${projectPath}:`);
        for (const name of mcpNames) {
          const isGlobal = GLOBAL_MCPS.includes(name);
          console.log(`    ${isGlobal ? '✅' : '⚠️ '} ${name}${isGlobal ? ' (global)' : ' (should this be a skill?)'}`);
        }
      }
    }
  }

  // Step 5: Write back (skip in dry-run mode)
  if (!isDryRun) {
    console.log("\n💾 Writing cleaned config...");
    try {
      writeFileSync(CLAUDE_JSON_PATH, JSON.stringify(claudeConfig, null, 2));
      console.log("✅ Config updated successfully\n");
    } catch (error) {
      console.error(`❌ Failed to write config: ${error}`);
      console.error(`⚠️  Restore from backup: cp ${BACKUP_PATH} ${CLAUDE_JSON_PATH}`);
      process.exit(1);
    }
  }

  // Step 6: Summary
  if (isDryRun) {
    console.log("\n═══════════════════════════════════════════════════════════════");
    console.log("  DRY RUN COMPLETE - No files were modified");
    console.log("═══════════════════════════════════════════════════════════════\n");

    if (totalRemoved > 0) {
      console.log("📊 Summary:");
      console.log(`   Would remove ${totalRemoved} MCP config(s) from ${projectsModified} project(s)`);
      console.log(`   File size would decrease by approximately ${Math.round(totalRemoved * 0.5)}KB\n`);

      console.log("🚀 To perform the actual cleanup:");
      console.log("   bun ~/.config/pai/scripts/cleanup-claude-mcps.ts\n");
    } else {
      console.log("✅ No skill-based MCPs found in project configs");
      console.log("   Nothing to clean up!\n");
    }
  } else {
    console.log("🎉 Cleanup complete!\n");
    console.log("Next steps:");
    console.log("  1. Restart Claude Code");
    console.log("  2. Verify global MCPs work (memory, ide, playwright, historian)");
    console.log("  3. Test skill-based loading: 'control lights' → loads home-assistant MCP");
    console.log("  4. Check resource usage: ps aux | grep -i mcp");
    console.log("\nIf anything breaks:");
    console.log(`  cp ${BACKUP_PATH} ${CLAUDE_JSON_PATH}`);
    console.log(`  # or from git-tracked backup:`);
    console.log(`  cp ${PAI_PRIVATE_BACKUP_PATH} ${CLAUDE_JSON_PATH}`);
  }
}

main().catch(console.error);
