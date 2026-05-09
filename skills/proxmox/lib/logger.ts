import { appendFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

/**
 * Logger with debug mode and audit trail support
 * Usage:
 *   logger.debug('Detailed info');  // Only shows with --debug flag
 *   logger.info('Normal output');   // Always shows
 *   logger.error('Error message');  // Always shows to stderr
 *   logger.audit('operation', {details});  // Logs to audit file
 */

export class Logger {
  private debugMode: boolean = false;
  private quietMode: boolean = false;
  private auditEnabled: boolean = true;
  private auditFile: string;

  constructor(args: string[] = process.argv) {
    this.debugMode = args.includes('--debug') || args.includes('-d');
    this.quietMode = args.includes('--quiet') || args.includes('-q');
    this.auditEnabled = !args.includes('--no-audit');

    // Audit log location: ~/.config/pai/skills/proxmox/logs/audit.log
    const logsDir = join(homedir(), '.config', 'pai', 'skills', 'proxmox', 'logs');
    this.auditFile = join(logsDir, 'audit.log');

    // Create logs directory if it doesn't exist
    try {
      const fs = require('fs');
      if (!fs.existsSync(logsDir)) {
        fs.mkdirSync(logsDir, { recursive: true });
      }
    } catch (err) {
      // Silently fail if can't create logs directory
    }
  }

  debug(message: string) {
    if (this.debugMode) {
      console.log(`🔍 DEBUG: ${message}`);
    }
  }

  info(message: string) {
    if (!this.quietMode) {
      console.log(message);
    }
  }

  success(message: string) {
    if (!this.quietMode) {
      console.log(`✅ ${message}`);
    }
  }

  warn(message: string) {
    console.warn(`⚠️  ${message}`);
  }

  error(message: string) {
    console.error(`❌ ${message}`);
  }

  // Always output, ignores quiet mode
  always(message: string) {
    console.log(message);
  }

  /**
   * Write audit trail entry
   * @param operation - Operation name (e.g., 'vm-start', 'container-exec')
   * @param details - Additional context (vmid, node, command, etc.)
   */
  audit(operation: string, details: Record<string, any> = {}) {
    if (!this.auditEnabled) return;

    try {
      const timestamp = new Date().toISOString();
      const user = process.env.USER || process.env.USERNAME || 'unknown';
      const entry = JSON.stringify({
        timestamp,
        user,
        operation,
        ...details
      });

      appendFileSync(this.auditFile, entry + '\n', 'utf-8');
      this.debug(`Audit logged: ${operation}`);
    } catch (err) {
      // Silently fail if can't write audit log
      this.debug(`Failed to write audit log: ${err}`);
    }
  }
}

export function createLogger(): Logger {
  return new Logger(process.argv);
}
