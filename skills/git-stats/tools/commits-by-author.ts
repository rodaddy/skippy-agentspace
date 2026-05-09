#!/usr/bin/env bun
/**
 * Commits By Author Analyzer
 *
 * Analyzes git commit counts per contributor
 * Usage: bun commits-by-author.ts [--repo PATH] [--limit N] [--all]
 */

import { execSync } from 'child_process';
import { existsSync } from 'fs';

interface AuthorStats {
  name: string;
  commits: number;
  percentage: number;
}

function parseArgs(): { repo: string; limit: number; showAll: boolean } {
  const args = process.argv.slice(2);

  if (args.includes('--help')) {
    console.log('Usage: bun commits-by-author.ts [OPTIONS]');
    console.log('');
    console.log('Analyze git commit counts per contributor');
    console.log('');
    console.log('Options:');
    console.log('  --repo PATH    Repository path (default: current directory)');
    console.log('  --limit N      Show top N contributors (default: 10)');
    console.log('  --all          Show all contributors (no limit)');
    console.log('  --help         Show this help message');
    console.log('');
    console.log('Examples:');
    console.log('  bun commits-by-author.ts');
    console.log('  bun commits-by-author.ts --repo /path/to/repo --limit 20');
    console.log('  bun commits-by-author.ts --all');
    process.exit(0);
  }

  let repo = '.';
  let limit = 10;
  let showAll = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--repo' && args[i + 1]) {
      repo = args[i + 1];
      i++;
    } else if (args[i] === '--limit' && args[i + 1]) {
      limit = parseInt(args[i + 1], 10);
      i++;
    } else if (args[i] === '--all') {
      showAll = true;
    }
  }

  return { repo, limit, showAll };
}

function getCommitsByAuthor(repo: string): AuthorStats[] {
  // Verify git repo exists
  if (!existsSync(`${repo}/.git`)) {
    throw new Error(`Not a git repository: ${repo}`);
  }

  try {
    // Get all commit authors
    const cmd = `cd "${repo}" && git log --all --format="%an" 2>/dev/null`;
    const output = execSync(cmd, { encoding: 'utf-8' }).trim();

    if (!output) {
      return [];
    }

    // Count commits per author
    const authors = output.split('\n');
    const counts: Record<string, number> = {};

    for (const author of authors) {
      if (author) {
        counts[author] = (counts[author] || 0) + 1;
      }
    }

    const totalCommits = authors.length;

    // Convert to array and add percentages
    const stats: AuthorStats[] = Object.entries(counts).map(([name, commits]) => ({
      name,
      commits,
      percentage: (commits / totalCommits) * 100
    }));

    // Sort by commit count (descending)
    return stats.sort((a, b) => b.commits - a.commits);

  } catch (error) {
    throw new Error(`Failed to analyze repository: ${error.message}`);
  }
}

function formatOutput(stats: AuthorStats[], repo: string, limit: number, showAll: boolean) {
  console.log('\n## 📊 Commits By Author\n');

  const repoPath = execSync(`cd "${repo}" && pwd`, { encoding: 'utf-8' }).trim();
  console.log(`**Repository:** ${repoPath}`);

  const totalCommits = stats.reduce((sum, s) => sum + s.commits, 0);
  console.log(`**Total commits:** ${totalCommits.toLocaleString()}\n`);
  console.log('─'.repeat(60));

  const displayCount = showAll ? stats.length : Math.min(limit, stats.length);

  console.log('\nRank  Author                        Commits    %');
  console.log('─'.repeat(60));

  for (let i = 0; i < displayCount; i++) {
    const stat = stats[i];
    const rank = (i + 1).toString().padStart(4);
    const name = stat.name.padEnd(25).substring(0, 25);
    const commits = stat.commits.toString().padStart(7);
    const pct = stat.percentage.toFixed(1).padStart(6);

    console.log(`${rank}  ${name}  ${commits}  ${pct}%`);
  }

  if (!showAll && stats.length > limit) {
    console.log(`\n... and ${stats.length - limit} more contributors`);
  }

  console.log('\n' + '─'.repeat(60) + '\n');
}

// Main execution
try {
  const { repo, limit, showAll } = parseArgs();
  const stats = getCommitsByAuthor(repo);

  if (stats.length === 0) {
    console.log('\n📭 No commits found in repository.\n');
    process.exit(0);
  }

  formatOutput(stats, repo, limit, showAll);
  process.exit(0);

} catch (error) {
  console.error(`\n❌ Error: ${error.message}\n`);
  process.exit(1);
}
