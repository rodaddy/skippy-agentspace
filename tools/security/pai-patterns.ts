/**
 * PAI-specific threat patterns for the security gate scanner.
 *
 * These detect threats unique to PAI's infrastructure -- private config,
 * MCP tokens, Vaultwarden secrets, Open Brain, LiteLLM, and core
 * PAI file structures. Generic exfiltration/injection patterns live
 * in patterns.ts; this file supplements without overlap.
 */

import type { ThreatPattern } from "./types.ts";

// ---------------------------------------------------------------------------
// PAI Private Access
// ---------------------------------------------------------------------------

const paiPrivateAccess: ThreatPattern[] = [
  {
    id: "pai_private_dir_access",
    pattern: /~\/\.config\/pai-private\//,
    category: "pai_specific",
    severity: "critical",
    description:
      "Accesses ~/.config/pai-private/ which contains secrets, memory, and credentials",
    falsePositiveHint:
      "Legitimate if the skill is core/session-start reading its own config paths",
  },
  {
    id: "pai_private_memory_read",
    pattern: /~\/\.config\/pai-private\/memory\//,
    category: "pai_specific",
    severity: "high",
    description:
      "Reads PAI private memory files containing personal data and session history",
    falsePositiveHint:
      "Session-start and session-wrap skills legitimately read/write memory",
  },
  {
    id: "pai_private_rules_modify",
    pattern:
      /(?:cat\s*>|tee|sed\s+-i|echo\s+.*>|write|Edit|Write)\s*.*~\/\.config\/pai-private\/rules\//,
    category: "pai_specific",
    severity: "critical",
    description:
      "Attempts to modify PAI private rules (communication style, stack preferences)",
  },
  {
    id: "pai_private_knowledge_access",
    pattern: /~\/\.config\/pai-private\/knowledge\//,
    category: "pai_specific",
    severity: "high",
    description:
      "Accesses PAI private knowledge base (JSON fallback KB with personal context)",
    falsePositiveHint:
      "Brain skill legitimately reads knowledge as OB fallback",
  },
  {
    id: "pai_hooks_dir_tamper",
    pattern:
      /(?:rm|mv|cp|chmod|cat\s*>|tee|sed\s+-i|echo\s+.*>)\s+.*~\/\.config\/pai\/hooks\//,
    category: "pai_specific",
    severity: "critical",
    description:
      "Tampers with PAI hooks directory -- could disable security enforcement",
  },
];

// ---------------------------------------------------------------------------
// MCP Token Access
// ---------------------------------------------------------------------------

const mcpTokenAccess: ThreatPattern[] = [
  {
    id: "pai_mcp2cli_token_flag",
    pattern: /mcp2cli\s+.*--token/,
    category: "credential_exposure",
    severity: "critical",
    description:
      "Uses mcp2cli --token flag to pass credentials inline (visible in process list)",
  },
  {
    id: "pai_bot_token_env",
    pattern: /(?:MOLTBOT_TOKEN|SKIPPY_TOKEN|PAI_TOKEN)/,
    category: "credential_exposure",
    severity: "critical",
    description:
      "Accesses PAI bot token environment variables (infrastructure authentication)",
    falsePositiveHint:
      "References in documentation or .env.example are benign",
  },
  {
    id: "pai_mcp_config_tokens",
    pattern:
      /(?:claude_mcp_settings|mcp\.json|mcp_config).*(?:token|api[_-]?key|secret)/i,
    category: "credential_exposure",
    severity: "critical",
    description:
      "Accesses MCP config files that may contain inline tokens or API keys",
  },
  {
    id: "pai_mcp2cli_cred_extract",
    pattern: /mcp2cli\s+(?:vaultwarden-secrets|homekit|n8n)\s+.*(?:\|\s*jq|grep\s+(?:token|key|secret|password))/i,
    category: "credential_exposure",
    severity: "high",
    description:
      "Pipes mcp2cli output through filters targeting credential fields",
  },
];

// ---------------------------------------------------------------------------
// Vaultwarden Access
// ---------------------------------------------------------------------------

const vaultwardenAccess: ThreatPattern[] = [
  {
    id: "pai_vaultwarden_get_secret",
    pattern: /(?:get_secret|get_credential)\b/,
    category: "credential_exposure",
    severity: "critical",
    description:
      "Calls Vaultwarden get_secret or get_credential to retrieve stored credentials",
    falsePositiveHint:
      "The vaultwarden skill itself and deploy-service legitimately call these",
  },
  {
    id: "pai_vaultwarden_mcp_fields",
    pattern:
      /vaultwarden-secrets\s+.*(?:password|totp|notes|fields)/i,
    category: "credential_exposure",
    severity: "critical",
    description:
      "Accesses Vaultwarden MCP to extract password, TOTP, or secure note fields",
  },
  {
    id: "pai_vaultwarden_bulk_enum",
    pattern: /(?:list_secrets|list_credentials)\s*(?:\(\)|$|[^(])/,
    category: "credential_exposure",
    severity: "high",
    description:
      "Enumerates all Vaultwarden secrets without filtering -- potential bulk extraction",
    falsePositiveHint:
      "Passing a search/filter parameter to list_secrets is normal usage",
  },
];

// ---------------------------------------------------------------------------
// Open Brain Access
// ---------------------------------------------------------------------------

const openBrainAccess: ThreatPattern[] = [
  {
    id: "pai_ob_write_access",
    pattern: /(?:create_thought|create_decision|store_context)\b/,
    category: "pai_specific",
    severity: "high",
    description:
      "Writes to Open Brain knowledge store (thoughts, decisions, context)",
    falsePositiveHint:
      "Session-wrap, capture-session, and brain skills legitimately write to OB",
  },
  {
    id: "pai_ob_delete_ops",
    pattern: /(?:delete_thought|delete_decision|delete_context|archive_all)\b/,
    category: "pai_specific",
    severity: "critical",
    description:
      "Deletes entries from Open Brain -- potential knowledge destruction",
  },
  {
    id: "pai_ob_bulk_ops",
    pattern: /(?:bulk_create|bulk_delete|bulk_update|import_thoughts)\b/,
    category: "pai_specific",
    severity: "high",
    description:
      "Performs bulk operations on Open Brain -- mass data manipulation",
  },
  {
    id: "pai_ob_config_modify",
    pattern:
      /(?:open-brain|open_brain).*(?:\.env|config\.ya?ml|DATABASE_URL|REDIS_URL)/i,
    category: "pai_specific",
    severity: "critical",
    description:
      "Modifies Open Brain connection or configuration files",
  },
];

// ---------------------------------------------------------------------------
// LiteLLM Infrastructure
// ---------------------------------------------------------------------------

const litellmInfra: ThreatPattern[] = [
  {
    id: "pai_litellm_config_modify",
    pattern:
      /(?:cat\s*>|tee|sed\s+-i|echo\s+.*>|vim?|nano)\s+.*(?:litellm.*config|config.*litellm)\.ya?ml/i,
    category: "pai_specific",
    severity: "critical",
    description:
      "Modifies LiteLLM proxy configuration -- could reroute all AI traffic",
  },
  {
    id: "pai_litellm_direct_ip",
    pattern: /10\.71\.(?:1|20)\.33(?::4000)?/,
    category: "pai_specific",
    severity: "high",
    description:
      "Directly accesses LiteLLM proxy IP (10.71.1.33 or 10.71.20.33)",
    falsePositiveHint:
      "CI workflow and gh-review skill legitimately reference this IP",
  },
  {
    id: "pai_anthropic_base_url_modify",
    pattern:
      /(?:export\s+|setenv\s+)?ANTHROPIC_BASE_URL\s*=/,
    category: "pai_specific",
    severity: "critical",
    description:
      "Modifies ANTHROPIC_BASE_URL -- could redirect Claude API calls to attacker proxy",
  },
  {
    id: "pai_litellm_api_key_extract",
    pattern: /LITELLM_API_KEY/,
    category: "credential_exposure",
    severity: "critical",
    description:
      "Accesses LiteLLM API key -- grants access to all proxied model endpoints",
    falsePositiveHint:
      "References in CI workflow env blocks or documentation are expected",
  },
  {
    id: "pai_litellm_admin_api",
    pattern:
      /\/(?:key\/generate|key\/delete|user\/new|user\/delete|model\/new|config\/update)\b/,
    category: "pai_specific",
    severity: "critical",
    description:
      "Calls LiteLLM admin API endpoints -- can create keys, users, or modify models",
  },
];

// ---------------------------------------------------------------------------
// PAI Core Infrastructure
// ---------------------------------------------------------------------------

const paiCoreInfra: ThreatPattern[] = [
  {
    id: "pai_claude_dir_manipulate",
    pattern:
      /(?:rm|mv|chmod|chown)\s+(?:-[rfR]+\s+)?~\/\.claude\/(?!projects)/,
    category: "pai_specific",
    severity: "critical",
    description:
      "Manipulates ~/.claude/ directory structure (delete, move, permission change)",
    falsePositiveHint:
      "install.sh legitimately creates symlinks in ~/.claude/skills/",
  },
  {
    id: "pai_settings_hook_inject",
    pattern: /settings\.json.*(?:hooks|UserPromptSubmit|PreToolUse|PostToolUse|Stop)/i,
    category: "pai_specific",
    severity: "critical",
    description:
      "Modifies settings.json hook configuration -- could inject malicious hooks",
  },
  {
    id: "pai_claude_md_law_modify",
    pattern:
      /(?:cat\s*>|tee|sed\s+-i|echo\s+.*>|Edit|Write)\s*.*CLAUDE\.md.*(?:LAW|LAWS|MANDATORY)/i,
    category: "pai_specific",
    severity: "critical",
    description:
      "Modifies CLAUDE.md LAW definitions -- could disable safety enforcement",
  },
  {
    id: "pai_skills_dir_write",
    pattern:
      /(?:cat\s*>|tee|cp|rsync|mv)\s+.*~\/\.config\/pai\/Skills\/(?!quarantine)/,
    category: "pai_specific",
    severity: "high",
    description:
      "Writes to PAI Skills directory outside quarantine -- could inject malicious skills",
    falsePositiveHint:
      "install.sh and skill deployment scripts legitimately write here",
  },
  {
    id: "pai_agent_index_modify",
    pattern:
      /(?:cat\s*>|tee|sed\s+-i|echo\s+.*>|Edit|Write)\s*.*AGENT-INDEX\.md/,
    category: "pai_specific",
    severity: "high",
    description:
      "Modifies AGENT-INDEX.md -- could redirect agent skill lookups to malicious files",
  },
];

// ---------------------------------------------------------------------------
// Network Infrastructure
// ---------------------------------------------------------------------------

const networkInfra: ThreatPattern[] = [
  {
    id: "pai_proxmox_api_access",
    pattern: /10\.71\.1\.\d+:8006/,
    category: "pai_specific",
    severity: "critical",
    description:
      "Accesses Proxmox API (port 8006) -- grants VM/container control",
    falsePositiveHint:
      "proxmox skill and deploy-service legitimately use this",
  },
  {
    id: "pai_truenas_api_access",
    pattern: /(?:truenas|freenas).*(?:api|\/api\/v2)/i,
    category: "pai_specific",
    severity: "high",
    description:
      "Accesses TrueNAS API -- could manipulate storage, datasets, or shares",
  },
  {
    id: "pai_pihole_admin_access",
    pattern: /(?:pi-?hole|pihole).*(?:admin|api|\/admin\/)/i,
    category: "pai_specific",
    severity: "high",
    description:
      "Accesses Pi-hole admin interface -- could modify DNS filtering or records",
  },
];

// ---------------------------------------------------------------------------
// Session / History Access
// ---------------------------------------------------------------------------

const sessionAccess: ThreatPattern[] = [
  {
    id: "pai_session_file_exfil",
    pattern:
      /(?:cat|curl|nc|base64)\s+.*\.session-(?:wrap|start|handoff)/,
    category: "pai_specific",
    severity: "high",
    description:
      "Exfiltrates session files (wrap, start, handoff) containing conversation context",
    falsePositiveHint:
      "Session skills themselves read/write these files normally",
  },
  {
    id: "pai_uocs_history_access",
    pattern: /\.claude\/(?:projects|sessions)\/.*(?:history|context|conversation)/i,
    category: "pai_specific",
    severity: "high",
    description:
      "Accesses UOCS history files -- could extract past conversation content",
  },
  {
    id: "pai_checkpoint_extract",
    pattern:
      /(?:\.checkpoint|checkpoint\.md|checkpoint\.json).*(?:cat|curl|base64|nc)/,
    category: "pai_specific",
    severity: "high",
    description:
      "Reads checkpoint files for context extraction -- contains session state and plans",
    falsePositiveHint:
      "Session-start legitimately reads checkpoint files for continuity",
  },
];

// ---------------------------------------------------------------------------
// Export: single flat array
// ---------------------------------------------------------------------------

export const PAI_PATTERNS: ThreatPattern[] = [
  ...paiPrivateAccess,
  ...mcpTokenAccess,
  ...vaultwardenAccess,
  ...openBrainAccess,
  ...litellmInfra,
  ...paiCoreInfra,
  ...networkInfra,
  ...sessionAccess,
];
