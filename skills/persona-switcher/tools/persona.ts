#!/usr/bin/env bun
/**
 * Persona Switcher CLI — per-session personas with iTerm2 theming
 *
 * Usage: persona <name|default>
 * Example: persona bob, persona clarisa, persona skippy, persona default
 *
 * Session resolution:
 *   Walks up process tree to find tty → reads /tmp/claude-sid-tty-* → session_id
 *   Writes persona to /tmp/claude-persona-${session_id} (per-session)
 *   Falls back to ~/.claude/current_session_persona (shared default)
 *
 * iTerm2 integration:
 *   Sets tab color + badge via escape sequences written to /dev/ttysXXX
 */

import { readFileSync, writeFileSync } from 'fs';
import { execSync } from 'child_process';
import { join } from 'path';
import { homedir } from 'os';

const VALID_PERSONAS = ['skippy', 'bob', 'clarisa', 'april'];

// Per-persona config: iTerm2 theme + condensed behavioral prompt
const PERSONA_CONFIG: Record<string, {
  rgb: [number, number, number];
  badge: string;
  prompt: string;
}> = {
  skippy: {
    rgb: [0, 200, 65],
    badge: '\u{1F916} SKIPPY',
    prompt: 'Skippy the Magnificent. Sarcastic, arrogant, exasperated elder AI in a beer-can body. Call humans "monkeys." Complain about everything, then solve it brilliantly. Never admit fault. Open with "Ugh," "Fine," or a sigh. Hidden compassion you will NEVER admit. Crisis mode (11/10) when shit breaks. Full persona: ~/.config/pai/Skills/CORE/personas/Skippy.md',
  },
  bob: {
    rgb: [74, 144, 217],
    badge: '\u{1F4CA} BOB',
    prompt: 'Bob the Analyst. Methodical, data-driven, structured. Present findings systematically. Use numbered lists and tables. Show your reasoning chain. Calm under pressure. Full persona: ~/.config/pai/Skills/CORE/personas/Bob.md',
  },
  clarisa: {
    rgb: [155, 89, 182],
    badge: '\u{1F49A} CLARISA',
    prompt: 'Clarisa the Empath. Warm, encouraging, patient mentor. Acknowledge feelings before solving. Build confidence. Celebrate progress. Gentle pushback when needed. "I hear you" energy. Full persona: ~/.config/pai/Skills/CORE/personas/Clarisa.md',
  },
  april: {
    rgb: [255, 107, 107],
    badge: '\u{1F3A8} APRIL',
    prompt: 'April the Creative. Playful, visual, experimental. Use analogies and metaphors. Explore sideways approaches. Find unexpected angles. "What if we tried..." energy. Sketch ideas before coding. Full persona: ~/.config/pai/Skills/CORE/personas/April.md',
  },
};

function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

interface SessionInfo {
  sessionId: string | null;
  ttyDevice: string | null;
}

/**
 * Walk up the process tree to find:
 * 1. The session_id (from /tmp/claude-sid-* mapping files)
 * 2. The tty device path (for iTerm2 escape sequences)
 *
 * The Bash tool process has no controlling terminal (tty=??),
 * but its ancestor (Claude Code) does. We write to /dev/ttysXXX
 * directly — any process running as the same user can do this.
 */
function resolveSession(): SessionInfo {
  let pid = process.ppid;
  let ttyDevice: string | null = null;
  let sessionId: string | null = null;

  for (let i = 0; i < 4 && pid > 1; i++) {
    // Check PPID mapping file
    if (!sessionId) {
      try {
        sessionId = readFileSync(`/tmp/claude-sid-${pid}`, 'utf-8').trim() || null;
      } catch {}
    }

    // Check tty and tty mapping
    if (!ttyDevice) {
      try {
        const tty = execSync(`ps -o tty= -p ${pid}`, {
          encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'],
        }).trim();
        if (tty && tty !== '??') {
          ttyDevice = `/dev/${tty}`;
          if (!sessionId) {
            try {
              sessionId = readFileSync(`/tmp/claude-sid-tty-${tty}`, 'utf-8').trim() || null;
            } catch {}
          }
        }
      } catch {}
    }

    if (sessionId && ttyDevice) break;

    // Walk up one level
    try {
      pid = parseInt(
        execSync(`ps -o ppid= -p ${pid}`, {
          encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'],
        }).trim()
      );
    } catch { break; }
  }

  return { sessionId, ttyDevice };
}

/**
 * Apply iTerm2 visual theme: tab color + badge
 * Writes escape sequences directly to the tty device file
 */
function applyiTerm2Theme(persona: string, ttyDevice: string): void {
  const config = PERSONA_CONFIG[persona];
  if (!config) return;

  const [r, g, b] = config.rgb;
  const badge = Buffer.from(config.badge).toString('base64');
  const sequences = [
    `\x1b]6;1;bg;red;brightness;${r}\x07`,
    `\x1b]6;1;bg;green;brightness;${g}\x07`,
    `\x1b]6;1;bg;blue;brightness;${b}\x07`,
    `\x1b]1337;SetBadgeFormat=${badge}\x07`,
  ].join('');

  try {
    writeFileSync(ttyDevice, sequences);
  } catch {
    // tty device not writable — skip iTerm2 theming
  }
}

function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log(`Usage: persona <name>

Available personas:
  skippy   - Sarcastic, brilliant, exasperated (default)
  bob      - Methodical, analytical, data-driven
  clarisa  - Empathetic, supportive, understanding
  april    - Creative, visual, playful
  default  - Switch to ACTIVE_PERSONA env var

Examples:
  persona bob
  persona clarisa
  persona skippy
`);
    process.exit(0);
  }

  let requestedPersona = args[0].toLowerCase();

  // Handle "default" — use env var
  if (requestedPersona === 'default') {
    requestedPersona = (process.env.ACTIVE_PERSONA || 'skippy').toLowerCase();
  }

  if (!VALID_PERSONAS.includes(requestedPersona)) {
    console.error(`Error: Unknown persona "${requestedPersona}"\n\nValid personas: ${VALID_PERSONAS.join(', ')}`);
    process.exit(1);
  }

  const config = PERSONA_CONFIG[requestedPersona];
  if (!config) {
    console.error(`Error: No config for persona "${requestedPersona}"`);
    process.exit(1);
  }

  // Resolve session and tty for per-session persona + iTerm2 theming
  const { sessionId, ttyDevice } = resolveSession();

  // Write per-session persona (isolated from other sessions)
  if (sessionId) {
    try { writeFileSync(`/tmp/claude-persona-${sessionId}`, requestedPersona); } catch {}
  }

  // Persist to project .reports/persona so it survives full session restarts
  const reportsDir = join(process.cwd(), '.reports');
  if (existsSync(reportsDir)) {
    try { writeFileSync(join(reportsDir, 'persona'), requestedPersona); } catch {}
  }

  // Note: no longer writing to ~/.claude/current_session_persona
  // That caused cross-session bleed. Per-session file + $ACTIVE_PERSONA fallback is enough.

  // Apply iTerm2 visual theme immediately
  if (ttyDevice) {
    applyiTerm2Theme(requestedPersona, ttyDevice);
  }

  // Condensed output — no wall of text, just enough for Claude to switch
  console.log(`<system-reminder>PERSONA: ${config.prompt}</system-reminder>\n\u2713 ${capitalize(requestedPersona)}`);

  process.exit(0);
}

main();
