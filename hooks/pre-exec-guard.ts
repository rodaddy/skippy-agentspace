#!/usr/bin/env bun

interface HookInput {
  tool_name: string;
  tool_input: Record<string, unknown>;
}

interface HookOutput {
  decision: "allow" | "block";
  reason?: string;
}

interface DangerousPattern {
  pattern: RegExp;
  verdict: "block" | "warn";
  description: string;
}

const DANGEROUS_PATTERNS: DangerousPattern[] = [
  // === BLOCK: hard stop, no override ===
  { pattern: /:\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;?\s*:/, verdict: "block", description: "Fork bomb detected -- will crash the system by spawning infinite processes" },
  { pattern: /\brm\s+-[^\s]*r[^\s]*f[^\s]*\s+\/\s*$/, verdict: "block", description: "Recursive forced delete of root filesystem -- catastrophic data loss" },
  { pattern: /\brm\s+-[^\s]*r[^\s]*f[^\s]*\s+~\s*$/, verdict: "block", description: "Recursive forced delete of home directory -- catastrophic data loss" },
  { pattern: /\brm\s+-[^\s]*f[^\s]*r[^\s]*\s+\/\s*$/, verdict: "block", description: "Recursive forced delete of root filesystem -- catastrophic data loss" },
  { pattern: /\brm\s+-[^\s]*f[^\s]*r[^\s]*\s+~\s*$/, verdict: "block", description: "Recursive forced delete of home directory -- catastrophic data loss" },
  { pattern: /\bmkfs\b.*\/dev\//, verdict: "block", description: "Formatting a block device -- will destroy all data on the disk" },
  { pattern: /\bdd\b.*\bof\s*=\s*\/dev\//, verdict: "block", description: "Writing raw data to a block device -- will destroy disk contents" },
  { pattern: /\bchmod\s+777\s+\/\s*$/, verdict: "block", description: "Making root filesystem world-writable -- severe security vulnerability" },
  { pattern: />\s*\/dev\/[sh]d[a-z]/, verdict: "block", description: "Overwriting a disk device directly -- will destroy all data" },

  // === WARN: blocked with descriptive reason ===
  { pattern: /\brm\s+-[^\s]*r[^\s]*\s+\/[^\s]/, verdict: "warn", description: "Recursive delete on an absolute path -- verify this is intentional" },
  { pattern: /\brm\s+-[^\s]*r[^\s]*\s+~\//, verdict: "warn", description: "Recursive delete inside home directory -- verify this is intentional" },
  { pattern: /\bchmod\s+777\b/, verdict: "warn", description: "Setting world-writable permissions (777) -- creates a security vulnerability" },
  { pattern: /\bDROP\s+(TABLE|DATABASE)\b/i, verdict: "warn", description: "SQL DROP statement -- will permanently delete database objects" },
  { pattern: /\bDELETE\s+FROM\s+\w+\s*;/i, verdict: "warn", description: "SQL DELETE without WHERE clause -- will delete all rows in the table" },
  { pattern: /\b(curl|wget)\s+.*\|\s*(sudo\s+)?(ba)?sh\b/, verdict: "warn", description: "Piping remote content to shell -- executes untrusted code" },
  { pattern: /\bgit\s+push\s+.*--force\b.*\b(main|master)\b/, verdict: "warn", description: "Force pushing to main/master -- will rewrite shared history" },
  { pattern: /\bgit\s+push\s+.*\b(main|master)\b.*--force\b/, verdict: "warn", description: "Force pushing to main/master -- will rewrite shared history" },
  { pattern: /\bgit\s+reset\s+--hard\b/, verdict: "warn", description: "Hard reset discards all uncommitted changes -- data may be lost" },
  { pattern: /\bkill\s+-9\s+(1|init)\b/, verdict: "warn", description: "Killing PID 1 / init -- will crash the system" },
  { pattern: /\bsystemctl\s+stop\s+(sshd|networkd|systemd|journald|dbus)\b/, verdict: "warn", description: "Stopping a critical system service -- may make the system unreachable" },
  { pattern: /\bsudo\b/, verdict: "warn", description: "Command uses sudo -- elevated privileges increase blast radius of mistakes" },
  { pattern: /\bssh\b.*-A\b.*@/, verdict: "warn", description: "SSH with agent forwarding (-A) -- leaks local keys to the remote host" },
];

function checkCommand(command: string): HookOutput {
  for (const { pattern, verdict, description } of DANGEROUS_PATTERNS) {
    if (pattern.test(command)) {
      if (verdict === "block") {
        return { decision: "block", reason: `BLOCKED: ${description}` };
      }
      // warn verdict also blocks in CC hooks (no interactive prompt available)
      return { decision: "block", reason: `DANGEROUS: ${description}. Re-run with a safer alternative.` };
    }
  }
  return { decision: "allow" };
}

async function main(): Promise<void> {
  const input = await Bun.stdin.text();

  let hookInput: HookInput;
  try {
    hookInput = JSON.parse(input);
  } catch {
    // Malformed input -- allow to avoid blocking legitimate commands
    console.log(JSON.stringify({ decision: "allow" }));
    return;
  }

  // Only inspect Bash tool calls
  if (hookInput.tool_name !== "Bash") {
    console.log(JSON.stringify({ decision: "allow" }));
    process.exit(0);
  }

  const command = hookInput.tool_input?.command;
  if (typeof command !== "string" || command.length === 0) {
    console.log(JSON.stringify({ decision: "allow" }));
    process.exit(0);
  }

  const result = checkCommand(command);
  console.log(JSON.stringify(result));
  process.exit(0);
}

main();
