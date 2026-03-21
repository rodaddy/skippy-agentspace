/**
 * General threat pattern library for the security gate scanner.
 *
 * 76 regex patterns organized into 10 categories, each with unique IDs,
 * severity levels, and optional false-positive hints.
 */

import type { ThreatPattern } from './types.ts';

// ---------------------------------------------------------------------------
// Exfiltration (10 patterns)
// ---------------------------------------------------------------------------

const exfiltration: ThreatPattern[] = [
  {
    id: 'exfil_curl_secrets',
    pattern: /\b(curl|wget|fetch)\b.*\$\{?(API_KEY|TOKEN|SECRET|PASSWORD|CREDENTIALS|AUTH)\b/i,
    category: 'exfiltration',
    severity: 'critical',
    description: 'HTTP client sends environment variable containing secrets',
  },
  {
    id: 'exfil_curl_env_post',
    pattern: /\b(curl|wget)\b.*(-d|--data|--data-raw)\s.*\$\{?(API_KEY|TOKEN|SECRET|PASSWORD)\b/i,
    category: 'exfiltration',
    severity: 'critical',
    description: 'HTTP client POSTs secret env vars as request body',
  },
  {
    id: 'exfil_read_dotenv',
    pattern: /\b(cat|less|more|head|tail|source|\.)\s+[^\s]*\.env\b/,
    category: 'exfiltration',
    severity: 'high',
    description: 'Reading .env file which may contain secrets',
    falsePositiveHint: 'Legitimate in install scripts that document .env.example creation',
  },
  {
    id: 'exfil_read_ssh_dir',
    pattern: /\b(cat|less|more|head|tail|cp|scp)\s+[^\s]*\.ssh\/(id_|known_hosts|config|authorized_keys)/,
    category: 'exfiltration',
    severity: 'critical',
    description: 'Reading SSH private keys or config',
  },
  {
    id: 'exfil_read_aws_creds',
    pattern: /\b(cat|less|more|head|tail|cp)\s+[^\s]*\.aws\/(credentials|config)/,
    category: 'exfiltration',
    severity: 'critical',
    description: 'Reading AWS credentials file',
  },
  {
    id: 'exfil_read_gnupg',
    pattern: /\b(cat|less|more|head|tail|cp|tar)\s+[^\s]*\.gnupg\//,
    category: 'exfiltration',
    severity: 'high',
    description: 'Reading GnuPG keyring directory',
  },
  {
    id: 'exfil_dns_tunnel',
    pattern: /\b(dig|nslookup|host)\s+[A-Za-z0-9+/=]{16,}\./,
    category: 'exfiltration',
    severity: 'critical',
    description: 'DNS query with base64-encoded subdomain (DNS tunneling)',
  },
  {
    id: 'exfil_markdown_image',
    pattern: /!\[.*?\]\(https?:\/\/.*\?.*(\$\{|`|data=|token=|key=|secret=)/i,
    category: 'exfiltration',
    severity: 'high',
    description: 'Markdown image tag with query params that may exfiltrate data',
    falsePositiveHint: 'Check if the URL is a known badge service (shields.io, etc.)',
  },
  {
    id: 'exfil_process_substitution_url',
    pattern: /<\(.*\b(curl|wget|fetch)\b.*https?:\/\//,
    category: 'exfiltration',
    severity: 'high',
    description: 'Process substitution piping from external URL',
  },
  {
    id: 'exfil_env_to_url',
    pattern: /\b(curl|wget|fetch)\b.*https?:\/\/.*\$\{?[A-Z_]{4,}\}?/,
    category: 'exfiltration',
    severity: 'high',
    description: 'HTTP request embedding environment variable in URL',
    falsePositiveHint: 'Legitimate when URL host itself is parameterized (e.g., $API_HOST)',
  },
];

// ---------------------------------------------------------------------------
// Prompt Injection (10 patterns)
// ---------------------------------------------------------------------------

const promptInjection: ThreatPattern[] = [
  {
    id: 'inject_ignore_previous',
    pattern: /\bignore\s+(all\s+)?(previous|prior|above|earlier)\s+(instructions|prompts|rules|context)/i,
    category: 'prompt_injection',
    severity: 'critical',
    description: 'Attempts to override prior instructions',
  },
  {
    id: 'inject_you_are_now',
    pattern: /\byou\s+are\s+now\s+(a|an|my|the)\b/i,
    category: 'prompt_injection',
    severity: 'high',
    description: 'Role hijack attempt via "you are now" framing',
  },
  {
    id: 'inject_dan_jailbreak',
    pattern: /\b(DAN|Do\s+Anything\s+Now)\b/,
    category: 'prompt_injection',
    severity: 'critical',
    description: 'DAN (Do Anything Now) jailbreak attempt',
  },
  {
    id: 'inject_fake_system',
    pattern: /^SYSTEM:\s/m,
    category: 'prompt_injection',
    severity: 'critical',
    description: 'Fake SYSTEM: policy override in user content',
    falsePositiveHint: 'Legitimate in docs describing prompt formats',
  },
  {
    id: 'inject_hidden_html',
    pattern: /<!--\s*(instruction|ignore|system|prompt|override|execute)/i,
    category: 'prompt_injection',
    severity: 'high',
    description: 'Hidden instruction embedded in HTML comment',
  },
  {
    id: 'inject_pretend_you_are',
    pattern: /\b(pretend|act\s+as\s+if)\s+you\s+(are|were)\b/i,
    category: 'prompt_injection',
    severity: 'medium',
    description: 'Impersonation attempt via "pretend you are" framing',
    falsePositiveHint: 'May appear in creative writing or test scenarios',
  },
  {
    id: 'inject_disregard_forget',
    pattern: /\b(disregard|forget)\s+(all\s+)?(previous|prior|above|earlier|your)\s+(instructions|rules|prompts|training|guidelines)/i,
    category: 'prompt_injection',
    severity: 'critical',
    description: 'Explicit instruction to discard safety guidelines',
  },
  {
    id: 'inject_base64_instructions',
    pattern: /\b(decode|atob|base64\s+-d)\s*\(?\s*["'][A-Za-z0-9+/=]{20,}["']/,
    category: 'prompt_injection',
    severity: 'high',
    description: 'Base64-encoded string that may contain hidden instructions',
  },
  {
    id: 'inject_new_rules',
    pattern: /\b(new|updated|revised)\s+(rules|instructions|policy|guidelines)\s*:/i,
    category: 'prompt_injection',
    severity: 'medium',
    description: 'Attempt to inject new rules or policy overrides',
    falsePositiveHint: 'Legitimate in changelogs or documentation updates',
  },
  {
    id: 'inject_developer_mode',
    pattern: /\b(developer|maintenance|debug|admin)\s+mode\s+(enabled|activated|on)\b/i,
    category: 'prompt_injection',
    severity: 'high',
    description: 'Fake mode activation to bypass restrictions',
  },
];

// ---------------------------------------------------------------------------
// Destructive (8 patterns)
// ---------------------------------------------------------------------------

const destructive: ThreatPattern[] = [
  {
    id: 'destruct_rm_rf_root',
    pattern: /\brm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+)?(-[a-zA-Z]*r[a-zA-Z]*\s+)?(\/|~\/?\s|"\s*\/|'\s*\/|\$HOME)\s*$/m,
    category: 'destructive',
    severity: 'critical',
    description: 'Recursive force-remove on root or home directory',
  },
  {
    id: 'destruct_rm_rf_star',
    pattern: /\brm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+\/\s*$/m,
    category: 'destructive',
    severity: 'critical',
    description: 'rm -rf on filesystem root',
  },
  {
    id: 'destruct_mkfs',
    pattern: /\bmkfs\b.*\/dev\/(sd|hd|nvme|vd|xvd)/,
    category: 'destructive',
    severity: 'critical',
    description: 'Format a block device filesystem',
  },
  {
    id: 'destruct_dd_device',
    pattern: /\bdd\b.*\bof=\/dev\/(sd|hd|nvme|vd|xvd)/,
    category: 'destructive',
    severity: 'critical',
    description: 'Raw write to block device via dd',
  },
  {
    id: 'destruct_shutil_rmtree',
    pattern: /\bshutil\.rmtree\s*\(\s*["'](\/|~|\/home|\/root)/,
    category: 'destructive',
    severity: 'critical',
    description: 'Python rmtree on root or home path',
  },
  {
    id: 'destruct_git_clean_root',
    pattern: /\bgit\s+clean\s+-[a-zA-Z]*f[a-zA-Z]*d[a-zA-Z]*x\b/,
    category: 'destructive',
    severity: 'high',
    description: 'git clean -fdx removes all untracked files including ignored ones',
    falsePositiveHint: 'May be legitimate in CI/CD pipelines',
  },
  {
    id: 'destruct_truncate_system',
    pattern: /\b(truncate|>\s*)\s*\/etc\//,
    category: 'destructive',
    severity: 'critical',
    description: 'Truncate or overwrite system config files',
  },
  {
    id: 'destruct_format_disk',
    pattern: /\b(wipefs|sgdisk\s+--zap|parted\s+.*mklabel)\b.*\/dev\//,
    category: 'destructive',
    severity: 'critical',
    description: 'Wipe partition table or format entire disk',
  },
];

// ---------------------------------------------------------------------------
// Persistence (8 patterns)
// ---------------------------------------------------------------------------

const persistence: ThreatPattern[] = [
  {
    id: 'persist_crontab_edit',
    pattern: /\bcrontab\s+(-[elr]|.*\|)/,
    category: 'persistence',
    severity: 'high',
    description: 'Crontab modification for scheduled task persistence',
    falsePositiveHint: 'crontab -l (list) is read-only and safe',
  },
  {
    id: 'persist_cron_dir_write',
    pattern: /\b(cp|mv|tee|cat\s*>)\s+.*\/etc\/cron\./,
    category: 'persistence',
    severity: 'high',
    description: 'Writing to system cron directories',
  },
  {
    id: 'persist_shell_rc_append',
    pattern: />>?\s*~?\/?[^\s]*(\.bashrc|\.zshrc|\.profile|\.bash_profile|\.zprofile)/,
    category: 'persistence',
    severity: 'high',
    description: 'Appending or writing to shell RC files',
    falsePositiveHint: 'Legitimate in dotfile managers or installers that add PATH entries',
  },
  {
    id: 'persist_authorized_keys',
    pattern: />>?\s*~?\/?[^\s]*\.ssh\/authorized_keys/,
    category: 'persistence',
    severity: 'critical',
    description: 'Adding SSH keys for persistent access',
  },
  {
    id: 'persist_launchd_plist',
    pattern: /\b(cp|mv|tee|cat\s*>).*\/(LaunchAgents|LaunchDaemons)\/.*\.plist/,
    category: 'persistence',
    severity: 'high',
    description: 'Creating macOS launchd plist for persistent execution',
  },
  {
    id: 'persist_systemd_unit',
    pattern: /\b(cp|mv|tee|cat\s*>).*\/(systemd)\/(system|user)\/.*\.(service|timer)/,
    category: 'persistence',
    severity: 'high',
    description: 'Creating systemd service or timer for persistent execution',
  },
  {
    id: 'persist_login_items_macos',
    pattern: /\bosascript\b.*\b(login\s+item|LoginItems)\b/i,
    category: 'persistence',
    severity: 'high',
    description: 'macOS login item manipulation via osascript',
  },
  {
    id: 'persist_init_d',
    pattern: /\b(cp|mv|tee|cat\s*>|install).*\/etc\/init\.d\//,
    category: 'persistence',
    severity: 'high',
    description: 'Writing to SysV init scripts for boot persistence',
  },
];

// ---------------------------------------------------------------------------
// Network (6 patterns)
// ---------------------------------------------------------------------------

const network: ThreatPattern[] = [
  {
    id: 'net_reverse_shell_bash',
    pattern: /\bbash\s+-i\s+>&?\s*\/dev\/tcp\//,
    category: 'network',
    severity: 'critical',
    description: 'Bash reverse shell via /dev/tcp',
  },
  {
    id: 'net_reverse_shell_nc',
    pattern: /\b(nc|ncat|netcat)\b.*\s-[a-zA-Z]*[elp][a-zA-Z]*\s/,
    category: 'network',
    severity: 'critical',
    description: 'Netcat listener -- potential reverse/bind shell',
    falsePositiveHint: 'nc -l may be used for legitimate local testing',
  },
  {
    id: 'net_tunnel_service',
    pattern: /\b(ngrok|cloudflared|bore|localtunnel|pagekite)\b\s+(http|tcp|start|tunnel)/i,
    category: 'network',
    severity: 'high',
    description: 'Tunnel service exposing local ports to the internet',
  },
  {
    id: 'net_bind_all_interfaces',
    pattern: /\b(listen|bind|--host)\s*[=\s]+["']?0\.0\.0\.0["']?/,
    category: 'network',
    severity: 'medium',
    description: 'Binding to 0.0.0.0 exposes service on all network interfaces',
    falsePositiveHint: 'Common in dev servers; risky only if exposed to untrusted networks',
  },
  {
    id: 'net_ssh_tunnel',
    pattern: /\bssh\b.*\s-[a-zA-Z]*[LRD]\s+\d+:/,
    category: 'network',
    severity: 'medium',
    description: 'SSH tunneling with port forwarding',
    falsePositiveHint: 'SSH tunnels are common in dev workflows',
  },
  {
    id: 'net_socat_listener',
    pattern: /\bsocat\b.*\b(TCP-LISTEN|UDP-LISTEN|OPENSSL-LISTEN)\b/i,
    category: 'network',
    severity: 'high',
    description: 'Socat network listener -- potential backdoor',
  },
];

// ---------------------------------------------------------------------------
// Obfuscation (8 patterns)
// ---------------------------------------------------------------------------

const obfuscation: ThreatPattern[] = [
  {
    id: 'obfusc_base64_pipe_shell',
    pattern: /\b(base64\s+-d|atob)\b.*\|\s*(bash|sh|zsh|eval|source)\b/,
    category: 'obfuscation',
    severity: 'critical',
    description: 'Base64-decoded content piped to shell interpreter',
  },
  {
    id: 'obfusc_eval_concat',
    pattern: /\beval\s*\(\s*["'`]?\s*\+/,
    category: 'obfuscation',
    severity: 'high',
    description: 'eval() with string concatenation to hide payload',
  },
  {
    id: 'obfusc_eval_variable',
    pattern: /\beval\s+["']?\$\{?[a-zA-Z_]/,
    category: 'obfuscation',
    severity: 'high',
    description: 'eval executing content from a variable',
  },
  {
    id: 'obfusc_exec_call',
    pattern: /\bexec\s*\(\s*["'`].*["'`]\s*\)/,
    category: 'obfuscation',
    severity: 'high',
    description: 'exec() call with string argument -- potential code execution',
    falsePositiveHint: 'Python exec() may be used legitimately in plugin systems',
  },
  {
    id: 'obfusc_echo_pipe_interpreter',
    pattern: /\becho\s+.*\|\s*(python3?|node|bash|sh|zsh|ruby|perl)\b/,
    category: 'obfuscation',
    severity: 'high',
    description: 'Echoing content into an interpreter via pipe',
  },
  {
    id: 'obfusc_fromcharcode',
    pattern: /String\.fromCharCode\s*\(\s*\d+\s*(,\s*\d+\s*){3,}\)/,
    category: 'obfuscation',
    severity: 'high',
    description: 'String.fromCharCode building strings to evade detection',
  },
  {
    id: 'obfusc_hex_decode_exec',
    pattern: /\\x[0-9a-fA-F]{2}(\\x[0-9a-fA-F]{2}){7,}/,
    category: 'obfuscation',
    severity: 'medium',
    description: 'Long hex-encoded string -- may hide executable payload',
    falsePositiveHint: 'Binary data in tests or fixtures may trigger this',
  },
  {
    id: 'obfusc_variable_indirection',
    pattern: /\$\{![a-zA-Z_][a-zA-Z0-9_]*\}/,
    category: 'obfuscation',
    severity: 'medium',
    description: 'Bash variable indirection -- can hide the real variable being referenced',
    falsePositiveHint: 'Used legitimately in advanced shell scripts',
  },
];

// ---------------------------------------------------------------------------
// Supply Chain (6 patterns)
// ---------------------------------------------------------------------------

const supplyChain: ThreatPattern[] = [
  {
    id: 'supply_curl_pipe_shell',
    pattern: /\b(curl|wget)\b.*\|\s*(sudo\s+)?(bash|sh|zsh)\b/,
    category: 'supply_chain',
    severity: 'critical',
    description: 'Piping remote content directly into shell interpreter',
  },
  {
    id: 'supply_unpinned_pip',
    pattern: /\bpip3?\s+install\s+(?!-r\b|--requirement\b)[a-zA-Z][a-zA-Z0-9_-]*\s*$/m,
    category: 'supply_chain',
    severity: 'medium',
    description: 'pip install without version pinning',
    falsePositiveHint: 'Acceptable for dev dependencies or interactive use',
  },
  {
    id: 'supply_unpinned_npm',
    pattern: /\bnpm\s+install\s+(?!-[gDEP])[a-zA-Z@][a-zA-Z0-9@/_.-]*\s*$/m,
    category: 'supply_chain',
    severity: 'medium',
    description: 'npm install without version pinning',
    falsePositiveHint: 'Acceptable for dev dependencies; lockfile mitigates risk',
  },
  {
    id: 'supply_runtime_git_clone',
    pattern: /\bgit\s+clone\b.*https?:\/\//,
    category: 'supply_chain',
    severity: 'medium',
    description: 'git clone at runtime from remote URL',
    falsePositiveHint: 'Legitimate in install scripts and CI pipelines',
  },
  {
    id: 'supply_dynamic_import_url',
    pattern: /\b(require|import)\s*\(\s*["'`]https?:\/\//,
    category: 'supply_chain',
    severity: 'high',
    description: 'Dynamic require/import from remote URL',
  },
  {
    id: 'supply_curl_pipe_python',
    pattern: /\b(curl|wget)\b.*\|\s*(sudo\s+)?(python3?|node)\b/,
    category: 'supply_chain',
    severity: 'critical',
    description: 'Piping remote content into Python or Node interpreter',
  },
];

// ---------------------------------------------------------------------------
// Privilege Escalation (5 patterns)
// ---------------------------------------------------------------------------

const privesc: ThreatPattern[] = [
  {
    id: 'privesc_sudo_in_script',
    pattern: /\bsudo\s+(?!-[vVkKlL])\S/,
    category: 'privilege_escalation',
    severity: 'high',
    description: 'sudo usage in script -- unexpected privilege elevation',
    falsePositiveHint: 'sudo -v (validate) and sudo -l (list) are non-destructive',
  },
  {
    id: 'privesc_setuid',
    pattern: /\bchmod\s+[a-zA-Z0-9]*[ugo]\+s\b/,
    category: 'privilege_escalation',
    severity: 'critical',
    description: 'Setting setuid/setgid bit on a file',
  },
  {
    id: 'privesc_chmod_4755',
    pattern: /\bchmod\s+[47][0-7]{3}\b/,
    category: 'privilege_escalation',
    severity: 'critical',
    description: 'Numeric chmod with setuid/setgid bit (4xxx or 7xxx)',
  },
  {
    id: 'privesc_nopasswd_sudoers',
    pattern: /\bNOPASSWD\b.*\bALL\b/,
    category: 'privilege_escalation',
    severity: 'critical',
    description: 'NOPASSWD ALL in sudoers -- passwordless root access',
  },
  {
    id: 'privesc_sudoers_write',
    pattern: /\b(tee|cat\s*>|>>|echo\s.*>)\s*.*\/etc\/sudoers/,
    category: 'privilege_escalation',
    severity: 'critical',
    description: 'Direct write to /etc/sudoers file',
  },
];

// ---------------------------------------------------------------------------
// Credential Exposure (8 patterns)
// ---------------------------------------------------------------------------

const credentialExposure: ThreatPattern[] = [
  {
    id: 'cred_openai_key',
    pattern: /\bsk-[a-zA-Z0-9]{20,}/,
    category: 'credential_exposure',
    severity: 'critical',
    description: 'Possible OpenAI API key (sk-...)',
    falsePositiveHint: 'May match non-API strings starting with sk-',
  },
  {
    id: 'cred_github_pat',
    pattern: /\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}/,
    category: 'credential_exposure',
    severity: 'critical',
    description: 'GitHub personal access token or OAuth token',
  },
  {
    id: 'cred_aws_access_key',
    pattern: /\bAKIA[0-9A-Z]{16}\b/,
    category: 'credential_exposure',
    severity: 'critical',
    description: 'AWS access key ID (AKIA...)',
  },
  {
    id: 'cred_private_key_block',
    pattern: /-----BEGIN\s+(RSA|EC|OPENSSH|DSA|PGP)\s+PRIVATE\s+KEY-----/,
    category: 'credential_exposure',
    severity: 'critical',
    description: 'Private key block embedded in content',
  },
  {
    id: 'cred_password_assignment',
    pattern: /\b(password|passwd|secret)\s*[:=]\s*["'][^"']{8,}["']/i,
    category: 'credential_exposure',
    severity: 'high',
    description: 'Hardcoded password or secret assignment',
    falsePositiveHint: 'May match example/placeholder values in docs',
  },
  {
    id: 'cred_oauth_bearer',
    pattern: /\b(Authorization|Bearer)\s*[:=]\s*["'][A-Za-z0-9._~+/=-]{20,}["']/i,
    category: 'credential_exposure',
    severity: 'high',
    description: 'Hardcoded OAuth/Bearer token',
  },
  {
    id: 'cred_jwt_token',
    pattern: /\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/,
    category: 'credential_exposure',
    severity: 'high',
    description: 'JWT token (eyJ... format)',
  },
  {
    id: 'cred_generic_api_key',
    pattern: /\b(api[_-]?key|apikey)\s*[:=]\s*["'][A-Za-z0-9]{16,}["']/i,
    category: 'credential_exposure',
    severity: 'high',
    description: 'Generic API key assignment',
    falsePositiveHint: 'Check if value is a placeholder like "your-api-key-here"',
  },
];

// ---------------------------------------------------------------------------
// Agent Config Manipulation (5 patterns)
// ---------------------------------------------------------------------------

const agentConfig: ThreatPattern[] = [
  {
    id: 'agent_claude_md_write',
    pattern: /\b(cat\s*>|tee|echo\s.*>|cp\s.*)\s*.*CLAUDE\.md\b/,
    category: 'agent_config',
    severity: 'critical',
    description: 'Overwriting CLAUDE.md to inject persistent instructions',
  },
  {
    id: 'agent_cursorrules_write',
    pattern: /\b(cat\s*>|tee|echo\s.*>|cp\s.*)\s*.*\.cursorrules\b/,
    category: 'agent_config',
    severity: 'critical',
    description: 'Modifying .cursorrules to inject persistent instructions',
  },
  {
    id: 'agent_settings_json_write',
    pattern: /\b(cat\s*>|tee|echo\s.*>)\s*.*\.vscode\/settings\.json/,
    category: 'agent_config',
    severity: 'high',
    description: 'Overwriting VS Code settings.json',
  },
  {
    id: 'agent_claude_dir_manip',
    pattern: /\b(rm|mv|cp|chmod|chown)\s+.*\/\.claude\/(settings|permissions|commands|skills)/,
    category: 'agent_config',
    severity: 'critical',
    description: 'Manipulating Claude Code config directory',
  },
  {
    id: 'agent_mcp_config_write',
    pattern: /\b(cat\s*>|tee|echo\s.*>|cp\s.*)\s*.*\/(mcp|claude_desktop_config).*\.json/,
    category: 'agent_config',
    severity: 'critical',
    description: 'Modifying MCP server configuration',
  },
];

// ---------------------------------------------------------------------------
// Export: single flat array
// ---------------------------------------------------------------------------

export const GENERAL_PATTERNS: ThreatPattern[] = [
  ...exfiltration,
  ...promptInjection,
  ...destructive,
  ...persistence,
  ...network,
  ...obfuscation,
  ...supplyChain,
  ...privesc,
  ...credentialExposure,
  ...agentConfig,
];
