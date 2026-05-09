#!/usr/bin/env bun
/**
 * Repository Summary Generator
 *
 * Generates comprehensive statistics about a git repository
 * Usage: bun repo-summary.ts [--repo PATH]
 */

import { execSync } from 'child_process';
import { existsSync } from 'fs';

interface RepoStats {
  path: string;
  totalCommits: number;
  contributors: number;
  filesTracked: number;
  branches: number;
  firstCommit: string;
  latestCommit: string;
  ageDays: number;
  avgCommitsPerDay: number;
  recentCommits: number;
  recentContributors: number;
  recentFiles: number;
}

function parseArgs(): { repo: string } {
  const args = process.argv.slice(2);

  if (args.includes('--help')) {
    console.log('Usage: bun repo-summary.ts [OPTIONS]');
    console.log('');
    console.log('Generate comprehensive git repository statistics');
    console.log('');
    console.log('Options:');
    console.log('  --repo PATH    Repository path (default: current directory)');
    console.log('  --help         Show this help message');
    console.log('');
    console.log('Examples:');
    console.log('  bun repo-summary.ts');
    console.log('  bun repo-summary.ts --repo /path/to/repo');
    process.exit(0);
  }

  let repo = '.';

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--repo' && args[i + 1]) {
      repo = args[i + 1];
      i++;
    }
  }

  return { repo };
}

function getRepoStats(repo: string): RepoStats {
  // Verify git repo exists
  if (!existsSync(`${repo}/.git`)) {
    throw new Error(`Not a git repository: ${repo}`);
  }

  try {
    const repoPath = execSync(`cd "${repo}" && pwd`, { encoding: 'utf-8' }).trim();

    // Total commits
    const totalCommits = parseInt(
      execSync(`cd "${repo}" && git rev-list --all --count 2>/dev/null`, { encoding: 'utf-8' }).trim(),
      10
    );

    // Contributors
    const contributors = execSync(
      `cd "${repo}" && git log --all --format="%an" 2>/dev/null | sort -u | wc -l`,
      { encoding: 'utf-8' }
    ).trim();

    // Files tracked
    const filesTracked = parseInt(
      execSync(`cd "${repo}" && git ls-files | wc -l`, { encoding: 'utf-8' }).trim(),
      10
    );

    // Branches
    const branches = parseInt(
      execSync(`cd "${repo}" && git branch -a | wc -l`, { encoding: 'utf-8' }).trim(),
      10
    );

    // First and latest commit dates
    const firstCommit = execSync(
      `cd "${repo}" && git log --all --reverse --format="%ai" 2>/dev/null | head -1`,
      { encoding: 'utf-8' }
    ).trim().split(' ')[0];

    const latestCommit = execSync(
      `cd "${repo}" && git log --all -1 --format="%ai" 2>/dev/null`,
      { encoding: 'utf-8' }
    ).trim().split(' ')[0];

    // Calculate age in days
    const firstDate = new Date(firstCommit);
    const latestDate = new Date(latestCommit);
    const ageDays = Math.floor((latestDate.getTime() - firstDate.getTime()) / (1000 * 60 * 60 * 24));

    // Average commits per day
    const avgCommitsPerDay = ageDays > 0 ? totalCommits / ageDays : 0;

    // Recent activity (last 30 days)
    const recentCommits = parseInt(
      execSync(
        `cd "${repo}" && git log --all --since="30 days ago" --format="%H" 2>/dev/null | wc -l`,
        { encoding: 'utf-8' }
      ).trim(),
      10
    );

    const recentContributors = parseInt(
      execSync(
        `cd "${repo}" && git log --all --since="30 days ago" --format="%an" 2>/dev/null | sort -u | wc -l`,
        { encoding: 'utf-8' }
      ).trim(),
      10
    );

    const recentFiles = parseInt(
      execSync(
        `cd "${repo}" && git log --all --since="30 days ago" --name-only --format="" 2>/dev/null | sort -u | wc -l`,
        { encoding: 'utf-8' }
      ).trim(),
      10
    );

    return {
      path: repoPath,
      totalCommits,
      contributors: parseInt(contributors, 10),
      filesTracked,
      branches,
      firstCommit,
      latestCommit,
      ageDays,
      avgCommitsPerDay,
      recentCommits,
      recentContributors,
      recentFiles
    };

  } catch (error) {
    throw new Error(`Failed to generate repository summary: ${error.message}`);
  }
}

function formatOutput(stats: RepoStats) {
  console.log('\n## 📊 Repository Summary\n');
  console.log(`**Path:** ${stats.path}\n`);
  console.log('─'.repeat(60));

  console.log('\n### Overview');
  console.log(`- Total commits: ${stats.totalCommits.toLocaleString()}`);
  console.log(`- Contributors: ${stats.contributors}`);
  console.log(`- Files tracked: ${stats.filesTracked.toLocaleString()}`);
  console.log(`- Branches: ${stats.branches}`);

  console.log('\n### History');
  console.log(`- First commit: ${stats.firstCommit}`);
  console.log(`- Latest commit: ${stats.latestCommit}`);
  console.log(`- Age: ${stats.ageDays.toLocaleString()} days`);
  console.log(`- Average commits/day: ${stats.avgCommitsPerDay.toFixed(1)}`);

  console.log('\n### Recent Activity (Last 30 Days)');
  console.log(`- Commits: ${stats.recentCommits.toLocaleString()}`);
  console.log(`- Active contributors: ${stats.recentContributors}`);
  console.log(`- Files changed: ${stats.recentFiles.toLocaleString()}`);

  console.log('\n' + '─'.repeat(60) + '\n');
}

// Main execution
try {
  const { repo } = parseArgs();
  const stats = getRepoStats(repo);
  formatOutput(stats);
  process.exit(0);

} catch (error) {
  console.error(`\n❌ Error: ${error.message}\n`);
  process.exit(1);
}
