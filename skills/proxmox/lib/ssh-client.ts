import { Client, ConnectConfig } from 'ssh2';
import { readFileSync } from 'fs';
import type { ProxmoxConfig, NodeConfig } from './config-loader.js';
import { getNode } from './config-loader.js';

export interface ExecResult {
  success: boolean;
  stdout: string;
  stderr: string;
  exit_code: number;
}

export class SSHClient {
  constructor(private config: ProxmoxConfig) {}

  private getConnectConfig(node: NodeConfig): ConnectConfig {
    return {
      host: node.hostname,
      port: node.ssh_port,
      username: node.ssh_user,
      privateKey: readFileSync(this.config.ssh.key_path),
      readyTimeout: this.config.ssh.connect_timeout * 1000
    };
  }

  /**
   * Get primary node for cluster operations
   * (Proxmox cluster allows managing all resources from any node)
   */
  private getPrimaryNode(): NodeConfig {
    // Try to find node with 'primary' role
    const primary = this.config.cluster.nodes.find(n =>
      n.enabled && n.roles.includes('primary')
    );

    // Fallback to first enabled node
    return primary || this.config.cluster.nodes.find(n => n.enabled)!;
  }

  /**
   * Execute command in container (non-streaming)
   * Connects to primary node - cluster routes to correct node automatically
   */
  async containerExec(
    vmid: number,
    command: string
  ): Promise<ExecResult> {
    const node = this.getPrimaryNode();

    return new Promise((resolve, reject) => {
      const conn = new Client();
      let stdout = '';
      let stderr = '';
      let exitCode = 0;

      conn.on('ready', () => {
        // Escape single quotes in command
        const escapedCmd = command.replace(/'/g, "'\\''");
        const sshCmd = `sudo pct exec ${vmid} -- bash -c '${escapedCmd}'`;

        conn.exec(sshCmd, (err, stream) => {
          if (err) {
            conn.end();
            return reject(err);
          }

          stream.on('data', (data: Buffer) => {
            stdout += data.toString();
          });

          stream.stderr.on('data', (data: Buffer) => {
            stderr += data.toString();
          });

          stream.on('close', (code: number) => {
            exitCode = code || 0;
            conn.end();

            resolve({
              success: exitCode === 0,
              stdout,
              stderr,
              exit_code: exitCode
            });
          });
        });
      });

      conn.on('error', (err) => {
        reject(err);
      });

      conn.connect(this.getConnectConfig(node));
    });
  }

  /**
   * Execute command with real-time streaming output
   * Connects to primary node - cluster routes to correct node automatically
   */
  async containerExecStream(
    vmid: number,
    command: string,
    onOutput: (data: string, isError: boolean) => void
  ): Promise<number> {
    const node = this.getPrimaryNode();

    return new Promise((resolve, reject) => {
      const conn = new Client();

      conn.on('ready', () => {
        const escapedCmd = command.replace(/'/g, "'\\''");
        const sshCmd = `sudo pct exec ${vmid} -- bash -c '${escapedCmd}'`;

        conn.exec(sshCmd, (err, stream) => {
          if (err) {
            conn.end();
            return reject(err);
          }

          // Real-time stdout streaming
          stream.on('data', (data: Buffer) => {
            onOutput(data.toString(), false);
          });

          // Real-time stderr streaming
          stream.stderr.on('data', (data: Buffer) => {
            onOutput(data.toString(), true);
          });

          stream.on('close', (code: number) => {
            conn.end();
            resolve(code || 0);
          });
        });
      });

      conn.on('error', (err) => {
        reject(err);
      });

      conn.connect(this.getConnectConfig(node));
    });
  }

  /**
   * Execute raw SSH command (not in container)
   */
  async exec(
    nodeName: string,
    command: string
  ): Promise<ExecResult> {
    const node = getNode(this.config, nodeName);

    return new Promise((resolve, reject) => {
      const conn = new Client();
      let stdout = '';
      let stderr = '';
      let exitCode = 0;

      conn.on('ready', () => {
        conn.exec(command, (err, stream) => {
          if (err) {
            conn.end();
            return reject(err);
          }

          stream.on('data', (data: Buffer) => {
            stdout += data.toString();
          });

          stream.stderr.on('data', (data: Buffer) => {
            stderr += data.toString();
          });

          stream.on('close', (code: number) => {
            exitCode = code || 0;
            conn.end();

            resolve({
              success: exitCode === 0,
              stdout,
              stderr,
              exit_code: exitCode
            });
          });
        });
      });

      conn.on('error', (err) => {
        reject(err);
      });

      conn.connect(this.getConnectConfig(node));
    });
  }
}
