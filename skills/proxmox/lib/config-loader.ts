import { config as loadEnv } from 'dotenv';
import { readFile } from 'fs/promises';
import { resolve } from 'path';

export interface NodeConfig {
  name: string;
  hostname: string;
  api_port: number;
  ssh_port: number;
  ssh_user: string;
  roles: string[];
  enabled: boolean;
}

export interface ProxmoxConfig {
  cluster: {
    name: string;
    nodes: NodeConfig[];
  };
  api: {
    verify_ssl: boolean;
    timeout: number;
    retry_attempts: number;
    retry_delay: number;
  };
  ssh: {
    key_path: string;
    connect_timeout: number;
    command_timeout: number;
    strict_host_key_checking: boolean;
  };
  defaults: {
    container_template: string;
    storage: string;
    network_bridge: string;
    gateway: string;
  };
  credentials: {
    api_user: string;
    api_token_name: string;
    api_token_secret: string;
  };
}

export async function loadConfig(): Promise<ProxmoxConfig> {
  const skillDir = resolve(process.env.HOME!, '.config/pai/skills/proxmox');

  // Load environment variables
  loadEnv({ path: resolve(skillDir, '.env') });

  // Load config.json
  const configPath = resolve(skillDir, 'config.json');
  const configData = await readFile(configPath, 'utf-8');
  const config = JSON.parse(configData) as Omit<ProxmoxConfig, 'credentials'>;

  // Merge with credentials from .env
  const fullConfig: ProxmoxConfig = {
    ...config,
    credentials: {
      api_user: process.env.PROXMOX_API_USER || 'root@pam',
      api_token_name: process.env.PROXMOX_API_TOKEN_NAME || 'claude-mcp',
      api_token_secret: process.env.PROXMOX_API_TOKEN_SECRET || ''
    }
  };

  // Expand SSH key path
  fullConfig.ssh.key_path = fullConfig.ssh.key_path.replace('~', process.env.HOME!);

  if (!fullConfig.credentials.api_token_secret) {
    throw new Error('PROXMOX_API_TOKEN_SECRET not set in .env');
  }

  return fullConfig;
}

export function getNode(config: ProxmoxConfig, nodeName: string): NodeConfig {
  const node = config.cluster.nodes.find(n => n.name === nodeName);
  if (!node) {
    throw new Error(`Node ${nodeName} not found in config`);
  }
  return node;
}

export function getEnabledNodes(config: ProxmoxConfig): NodeConfig[] {
  return config.cluster.nodes.filter(n => n.enabled);
}
