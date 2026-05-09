import axios, { AxiosInstance } from 'axios';
import https from 'https';
import type { ProxmoxConfig, NodeConfig } from './config-loader.js';

export interface ContainerInfo {
  vmid: number;
  name: string;
  status: 'running' | 'stopped';
  cpus?: number;
  maxmem?: number;
  mem?: number;
  uptime?: number;
  node?: string;
}

export interface VMInfo {
  vmid: number;
  name: string;
  status: 'running' | 'stopped';
  cpus?: number;
  maxmem?: number;
  mem?: number;
  uptime?: number;
  node?: string;
}

export interface NodeStatus {
  node: string;
  status: 'online' | 'offline';
  uptime: number;
  cpu: number;
  maxcpu: number;
  mem: number;
  maxmem: number;
}

export class ProxmoxAPIClient {
  private clients: Map<string, AxiosInstance> = new Map();

  constructor(private config: ProxmoxConfig) {
    this.initializeClients();
  }

  private initializeClients() {
    for (const node of this.config.cluster.nodes.filter(n => n.enabled)) {
      const client = axios.create({
        baseURL: `https://${node.hostname}:${node.api_port}/api2/json`,
        timeout: this.config.api.timeout,
        httpsAgent: new https.Agent({
          rejectUnauthorized: this.config.api.verify_ssl
        }),
        headers: {
          Authorization: `PVEAPIToken=${this.config.credentials.api_user}!${this.config.credentials.api_token_name}=${this.config.credentials.api_token_secret}`
        }
      });

      this.clients.set(node.name, client);
    }
  }

  private getClient(nodeName: string): AxiosInstance {
    const client = this.clients.get(nodeName);
    if (!client) {
      throw new Error(`No API client initialized for node ${nodeName}`);
    }
    return client;
  }

  async listContainers(nodeName: string): Promise<ContainerInfo[]> {
    const client = this.getClient(nodeName);
    const { data } = await client.get(`/nodes/${nodeName}/lxc`);
    return data.data;
  }

  async getContainerStatus(nodeName: string, vmid: number): Promise<any> {
    const client = this.getClient(nodeName);
    const { data } = await client.get(`/nodes/${nodeName}/lxc/${vmid}/status/current`);
    return data.data;
  }

  async startContainer(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/lxc/${vmid}/status/start`);
    return data.data; // Returns task ID
  }

  async stopContainer(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/lxc/${vmid}/status/stop`);
    return data.data; // Returns task ID
  }

  async shutdownContainer(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/lxc/${vmid}/status/shutdown`);
    return data.data;
  }

  async rebootContainer(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/lxc/${vmid}/status/reboot`);
    return data.data;
  }

  async listVMs(nodeName: string): Promise<VMInfo[]> {
    const client = this.getClient(nodeName);
    const { data } = await client.get(`/nodes/${nodeName}/qemu`);
    return data.data;
  }

  async getVMStatus(nodeName: string, vmid: number): Promise<any> {
    const client = this.getClient(nodeName);
    const { data} = await client.get(`/nodes/${nodeName}/qemu/${vmid}/status/current`);
    return data.data;
  }

  async startVM(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/qemu/${vmid}/status/start`);
    return data.data; // Returns task ID
  }

  async stopVM(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/qemu/${vmid}/status/stop`);
    return data.data; // Returns task ID
  }

  async shutdownVM(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/qemu/${vmid}/status/shutdown`);
    return data.data;
  }

  async rebootVM(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/qemu/${vmid}/status/reboot`);
    return data.data;
  }

  async pauseVM(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/qemu/${vmid}/status/suspend`);
    return data.data;
  }

  async resumeVM(nodeName: string, vmid: number): Promise<string> {
    const client = this.getClient(nodeName);
    const { data } = await client.post(`/nodes/${nodeName}/qemu/${vmid}/status/resume`);
    return data.data;
  }

  async getNodeStatus(nodeName: string): Promise<NodeStatus> {
    const client = this.getClient(nodeName);
    const { data } = await client.get(`/nodes/${nodeName}/status`);
    return {
      node: nodeName,
      ...data.data
    };
  }

  async getClusterStatus(): Promise<any> {
    // Query first available node
    const firstNode = this.config.cluster.nodes.find(n => n.enabled);
    if (!firstNode) throw new Error('No enabled nodes');

    const client = this.getClient(firstNode.name);
    const { data } = await client.get('/cluster/status');
    return data.data;
  }

  async getClusterResources(): Promise<any> {
    const firstNode = this.config.cluster.nodes.find(n => n.enabled);
    if (!firstNode) throw new Error('No enabled nodes');

    const client = this.getClient(firstNode.name);
    const { data } = await client.get('/cluster/resources');
    return data.data;
  }
}
