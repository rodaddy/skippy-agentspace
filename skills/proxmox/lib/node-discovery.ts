import type { ProxmoxConfig } from './config-loader.js';
import { ProxmoxAPIClient, type ContainerInfo, type VMInfo } from './api-client.js';
import { getEnabledNodes } from './config-loader.js';

export interface ContainerLocation {
  node: string;
  hostname: string;
  container: ContainerInfo;
}

export interface VMLocation {
  node: string;
  hostname: string;
  vm: VMInfo;
}

export class NodeDiscovery {
  private apiClient: ProxmoxAPIClient;

  constructor(private config: ProxmoxConfig) {
    this.apiClient = new ProxmoxAPIClient(config);
  }

  /**
   * Find which node has a specific container
   */
  async findContainer(vmid: number): Promise<ContainerLocation> {
    const nodes = getEnabledNodes(this.config);

    for (const node of nodes) {
      try {
        const containers = await this.apiClient.listContainers(node.name);
        const container = containers.find(c => c.vmid === vmid);

        if (container) {
          return {
            node: node.name,
            hostname: node.hostname,
            container
          };
        }
      } catch (error) {
        console.error(`Failed to query ${node.name}: ${error}`);
        // Continue to next node
      }
    }

    throw new Error(`Container ${vmid} not found on any node`);
  }

  /**
   * Find which node has a specific VM
   */
  async findVM(vmid: number): Promise<VMLocation> {
    const nodes = getEnabledNodes(this.config);

    for (const node of nodes) {
      try {
        const vms = await this.apiClient.listVMs(node.name);
        const vm = vms.find(v => v.vmid === vmid);

        if (vm) {
          return {
            node: node.name,
            hostname: node.hostname,
            vm
          };
        }
      } catch (error) {
        console.error(`Failed to query ${node.name}: ${error}`);
      }
    }

    throw new Error(`VM ${vmid} not found on any node`);
  }

  /**
   * List all containers across all nodes
   */
  async listAllContainers(): Promise<ContainerInfo[]> {
    const nodes = getEnabledNodes(this.config);
    const allContainers: ContainerInfo[] = [];

    await Promise.all(
      nodes.map(async (node) => {
        try {
          const containers = await this.apiClient.listContainers(node.name);
          containers.forEach(c => {
            c.node = node.name;
            allContainers.push(c);
          });
        } catch (error) {
          console.error(`Failed to list containers on ${node.name}: ${error}`);
        }
      })
    );

    return allContainers;
  }

  /**
   * List all VMs across all nodes
   */
  async listAllVMs(): Promise<VMInfo[]> {
    const nodes = getEnabledNodes(this.config);
    const allVMs: VMInfo[] = [];

    await Promise.all(
      nodes.map(async (node) => {
        try {
          const vms = await this.apiClient.listVMs(node.name);
          vms.forEach(v => {
            v.node = node.name;
            allVMs.push(v);
          });
        } catch (error) {
          console.error(`Failed to list VMs on ${node.name}: ${error}`);
        }
      })
    );

    return allVMs;
  }
}
