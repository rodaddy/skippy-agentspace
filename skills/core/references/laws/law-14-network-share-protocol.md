# LAW 14: Network Share Protocol Policy

**Enforcement:** Manual -- hook required (Phase 7 gap)
**Severity:** MANDATORY

## Rule

Network shares must be exported as both SMB and NFS so clients pick the right protocol.

## Why

Different clients work better with different protocols. macOS and Windows work best with SMB. Linux containers often work better with NFS (fewer ghost directories, less stale cache). Exporting both ensures each client can use the optimal protocol.

## Protocol Selection by Client

| Client Type | Protocol | Rationale |
|-------------|----------|-----------|
| macOS/Windows | SMB | Native support, best integration |
| Linux containers | NFS preferred | Fewer ghost dirs, less stale cache |
| External apps | Best fit | Use whichever protocol works best for the use case |

## Enforcement Details

Currently manually enforced -- no hook exists for this LAW yet.

A future hook would need to:
- Detect mount commands or share configuration in Bash tool calls
- Verify protocol selection matches client type
- Warn when SMB is used on Linux or NFS on macOS without explicit justification

## Examples

**Correct:** Mounting an SMB share on macOS, NFS share on a Linux container.
**Incorrect:** Using NFS on macOS when SMB is available, or using SMB on Linux when NFS would avoid known caching issues.

## Exceptions

- When one protocol has a specific feature needed for the use case
- Fallback scenarios where the preferred protocol isn't available
