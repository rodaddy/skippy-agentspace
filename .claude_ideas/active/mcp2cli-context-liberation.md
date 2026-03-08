# mcp2cli: Context Liberation

> Early ideation -- no work done yet. Inspiration from video watched 2026-03-08.

## Bob's Analysis (2026-03-08)

### Architecture Assessment
- The two-layer split (proxy for built-in stripping, mcp2cli for MCP elimination) is correct. No interaction between layers. Each developed independently.
- Skill files as routing tables (~200 tokens) vs full MCP schemas (~3,300-5,700 tokens) is a 16x compression ratio with zero capability loss.
- The core insight is an inversion of control: "load nothing, discover on demand" beats "load everything, strip what you don't need."

### Concerns Evaluated
1. **Latency (MEDIUM -> LOW)**: 25-50ms per bash subprocess is negligible for human-interactive use. Only matters for automated swarm agents chaining many calls. Not a blocker.
2. **Schema reliability (LOW)**: As long as skippy-agentspace skill files are the source of truth for tool discovery, agents won't hallucinate parameters. Runtime `schema` command is the safety net.
3. **Error handling (LOW)**: Solvable with consistent JSON output format. Build it in from day one.
4. **Bash injection surface (MEDIUM)**: All MCP ops routed through bash means input hardening is existential, not optional. The gws-cli 40+ validation test pattern should be ported early. Phase 11's injection fixes are a preview of the problem space.

### Migration Strategy
- User plans to prototype both n8n and vaultwarden in parallel to see what works
- n8n is the harder problem (19 tools, complex state) but the biggest win (5,700 tokens)
- vaultwarden is simpler but lower marginal benefit (already well-served by skill + get_credential)
- If n8n works clean, everything else is trivial

### Impact on Agentspace
- v1.2 phases 11-16 are unaffected (shell library, tests, GSD absorption, audit swarm, hardening, polish)
- v2 agentspace proxy scope dramatically simplified -- only needs built-in tool stripping (static deny-list), no MCP stripping/re-injection
- mcp2cli is a separate repo/project, not part of skippy-agentspace
