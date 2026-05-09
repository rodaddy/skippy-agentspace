#!/usr/bin/env bun
/**
 * PAI Session Viewer
 *
 * Shows session summaries from history
 * Usage: bun show-sessions.ts [--days 7] [--limit 10]
 */

import { execSync } from 'child_process';
import { existsSync, readdirSync, readFileSync, statSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const PAI_HOME = process.env.PAI_HOME || join(homedir(), '.config', 'pai');
const SESSIONS_DIR = join(PAI_HOME, 'history', 'sessions');

interface Session {
  file: string;
  timestamp: string;
  name: string;
  tools: string[];
  filesModified: number;
  mtime: Date;
}

function parseArgs(): { days: number; limit: number } {
  const args = process.argv.slice(2);
  let days = 7;
  let limit = 10;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--days' && args[i + 1]) {
      days = parseInt(args[i + 1], 10);
      i++;
    } else if (args[i] === '--limit' && args[i + 1]) {
      limit = parseInt(args[i + 1], 10);
      i++;
    }
  }

  return { days, limit };
}

function parseSessionFile(filePath: string): Session | null {
  try {
    const content = readFileSync(filePath, 'utf-8');
    const stat = statSync(filePath);
    const filename = filePath.split('/').pop() || '';

    // Extract timestamp from filename
    const timestampMatch = filename.match(/^(\d{8}T\d{6})/);
    const timestamp = timestampMatch ?
      timestampMatch[1].replace(/(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})/, '$1-$2-$3 $4:$5') :
      'unknown';

    // Extract session name from filename
    const nameMatch = filename.match(/_SESSION_(.+)\.md$/);
    const name = nameMatch ? nameMatch[1].replace(/-/g, ' ') : 'unknown';

    // Parse tools used
    const toolsMatch = content.match(/## Tools Used\n\n([\s\S]*?)\n\n---/);
    const tools: string[] = [];
    if (toolsMatch) {
      const toolLines = toolsMatch[1].trim().split('\n');
      for (const line of toolLines) {
        const tool = line.replace(/^- /, '').trim();
        if (tool) tools.push(tool);
      }
    }

    // Count files modified
    const filesMatch = content.match(/## Files Modified\n\n([\s\S]*?)\n\n---/);
    const filesModified = filesMatch ?
      filesMatch[1].trim().split('\n').filter(l => l.startsWith('-')).length :
      0;

    return {
      file: filePath,
      timestamp,
      name,
      tools,
      filesModified,
      mtime: stat.mtime
    };
  } catch (error) {
    return null;
  }
}

function getRecentSessions(days: number): Session[] {
  if (!existsSync(SESSIONS_DIR)) {
    return [];
  }

  const sessions: Session[] = [];
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  // Get all month directories
  const monthDirs = readdirSync(SESSIONS_DIR)
    .map(d => join(SESSIONS_DIR, d))
    .filter(d => statSync(d).isDirectory());

  for (const monthDir of monthDirs) {
    const files = readdirSync(monthDir)
      .filter(f => f.endsWith('.md'))
      .map(f => join(monthDir, f));

    for (const file of files) {
      const stat = statSync(file);
      if (stat.mtime >= cutoffDate) {
        const session = parseSessionFile(file);
        if (session) sessions.push(session);
      }
    }
  }

  // Sort by mtime (newest first)
  return sessions.sort((a, b) => b.mtime.getTime() - a.mtime.getTime());
}

function formatSessions(sessions: Session[], limit: number) {
  console.log('\n## 📋 Recent Sessions\n');
  console.log(`**Showing:** Last ${sessions.length} sessions\n`);
  console.log('─'.repeat(60));

  for (const session of sessions.slice(0, limit)) {
    console.log(`\n### ${session.timestamp} - ${session.name}`);
    console.log(`**Tools:** ${session.tools.slice(0, 5).join(', ')}${session.tools.length > 5 ? `, +${session.tools.length - 5} more` : ''}`);
    console.log(`**Files modified:** ${session.filesModified}`);
    console.log(`**Path:** \`${session.file.replace(PAI_HOME + '/', '')}\``);
  }

  if (sessions.length > limit) {
    console.log(`\n*Showing ${limit} of ${sessions.length} sessions. Use --limit N to see more.*`);
  }

  console.log('\n' + '─'.repeat(60) + '\n');
}

// Main
const { days, limit } = parseArgs();

if (!existsSync(SESSIONS_DIR)) {
  console.error(`❌ Sessions directory not found: ${SESSIONS_DIR}`);
  console.error('   PAI may not have captured any sessions yet.');
  process.exit(1);
}

const sessions = getRecentSessions(days);

if (sessions.length === 0) {
  console.log(`\n📭 No sessions found in the last ${days} days.\n`);
  process.exit(0);
}

formatSessions(sessions, limit);
