#!/usr/bin/env bun
/**
 * PAI Tool Usage Analyzer
 *
 * Analyzes tool usage patterns from JSONL event logs
 * Usage: bun analyze-tools.ts [--date YYYY-MM-DD] [--days 7]
 */

import { execSync } from 'child_process';
import { existsSync, readdirSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const PAI_HOME = process.env.PAI_HOME || join(homedir(), '.config', 'pai');
const RAW_OUTPUTS_DIR = join(PAI_HOME, 'history', 'raw-outputs');

interface ToolStats {
  tool: string;
  count: number;
  percentage: number;
}

interface EventStats {
  eventType: string;
  count: number;
}

function parseArgs(): { date: string | null; days: number } {
  const args = process.argv.slice(2);
  let date: string | null = null;
  let days = 7;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--date' && args[i + 1]) {
      date = args[i + 1];
      i++;
    } else if (args[i] === '--days' && args[i + 1]) {
      days = parseInt(args[i + 1], 10);
      i++;
    }
  }

  return { date, days };
}

function getJSONLFiles(date: string | null, days: number): string[] {
  if (!existsSync(RAW_OUTPUTS_DIR)) {
    return [];
  }

  const files: string[] = [];

  if (date) {
    // Specific date
    const [year, month] = date.split('-');
    const monthDir = join(RAW_OUTPUTS_DIR, `${year}-${month}`);
    if (existsSync(monthDir)) {
      const file = join(monthDir, `${date}_all-events.jsonl`);
      if (existsSync(file)) files.push(file);

      // Also check for tool-outputs
      const toolFile = join(monthDir, `${date}_tool-outputs.jsonl`);
      if (existsSync(toolFile)) files.push(toolFile);
    }
  } else {
    // Last N days
    const now = new Date();
    for (let i = 0; i < days; i++) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const [year, month] = dateStr.split('-');
      const monthDir = join(RAW_OUTPUTS_DIR, `${year}-${month}`);

      if (existsSync(monthDir)) {
        const file = join(monthDir, `${dateStr}_all-events.jsonl`);
        if (existsSync(file)) files.push(file);

        const toolFile = join(monthDir, `${dateStr}_tool-outputs.jsonl`);
        if (existsSync(toolFile)) files.push(toolFile);
      }
    }
  }

  return files;
}

function analyzeToolUsage(files: string[]): ToolStats[] {
  const toolCounts: Record<string, number> = {};
  let totalTools = 0;

  for (const file of files) {
    try {
      const cmd = `cat "${file}" | jq -r 'select(.payload.tool_name != null) | .payload.tool_name' 2>/dev/null || true`;
      const output = execSync(cmd, { encoding: 'utf-8' }).trim();

      if (output) {
        const tools = output.split('\n');
        for (const tool of tools) {
          if (tool) {
            toolCounts[tool] = (toolCounts[tool] || 0) + 1;
            totalTools++;
          }
        }
      }
    } catch (error) {
      // Skip file on error
    }
  }

  // Convert to array and calculate percentages
  const stats: ToolStats[] = Object.entries(toolCounts).map(([tool, count]) => ({
    tool,
    count,
    percentage: (count / totalTools) * 100
  }));

  // Sort by count (descending)
  return stats.sort((a, b) => b.count - a.count);
}

function analyzeEventTypes(files: string[]): EventStats[] {
  const eventCounts: Record<string, number> = {};

  for (const file of files) {
    try {
      const cmd = `cat "${file}" | jq -r '.hook_event_type' 2>/dev/null || true`;
      const output = execSync(cmd, { encoding: 'utf-8' }).trim();

      if (output) {
        const events = output.split('\n');
        for (const event of events) {
          if (event && event !== 'null') {
            eventCounts[event] = (eventCounts[event] || 0) + 1;
          }
        }
      }
    } catch (error) {
      // Skip file on error
    }
  }

  const stats: EventStats[] = Object.entries(eventCounts).map(([eventType, count]) => ({
    eventType,
    count
  }));

  return stats.sort((a, b) => b.count - a.count);
}

function formatResults(toolStats: ToolStats[], eventStats: EventStats[], date: string | null, days: number) {
  console.log('\n## 📊 Tool Usage Analysis\n');

  if (date) {
    console.log(`**Date:** ${date}`);
  } else {
    console.log(`**Period:** Last ${days} days`);
  }

  const totalTools = toolStats.reduce((sum, s) => sum + s.count, 0);
  const totalEvents = eventStats.reduce((sum, s) => sum + s.count, 0);

  console.log(`**Total tool uses:** ${totalTools}`);
  console.log(`**Total events:** ${totalEvents}\n`);
  console.log('─'.repeat(60));

  if (toolStats.length > 0) {
    console.log('\n### 🔧 Most Used Tools\n');
    for (const stat of toolStats.slice(0, 10)) {
      const bar = '█'.repeat(Math.ceil(stat.percentage / 5));
      console.log(`${stat.tool.padEnd(20)} ${stat.count.toString().padStart(4)} ${bar} ${stat.percentage.toFixed(1)}%`);
    }

    if (toolStats.length > 10) {
      console.log(`\n... and ${toolStats.length - 10} more tools`);
    }
  }

  if (eventStats.length > 0) {
    console.log('\n### 📡 Event Types\n');
    for (const stat of eventStats.slice(0, 10)) {
      console.log(`- ${stat.eventType}: ${stat.count}`);
    }
  }

  console.log('\n' + '─'.repeat(60) + '\n');
}

// Main
const { date, days } = parseArgs();

if (!existsSync(RAW_OUTPUTS_DIR)) {
  console.error(`❌ Raw outputs directory not found: ${RAW_OUTPUTS_DIR}`);
  console.error('   PAI may not have captured any tool usage yet.');
  process.exit(1);
}

const files = getJSONLFiles(date, days);

if (files.length === 0) {
  console.log(`\n📭 No tool usage data found${date ? ` for ${date}` : ` in the last ${days} days`}.\n`);
  process.exit(0);
}

const toolStats = analyzeToolUsage(files);
const eventStats = analyzeEventTypes(files);

formatResults(toolStats, eventStats, date, days);
