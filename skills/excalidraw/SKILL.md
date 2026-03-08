---
name: excalidraw
description: Generate Excalidraw diagrams from natural language using a Mermaid-based pipeline.
metadata:
  version: 0.1.0
  author: Rico
  source: https://github.com/rico/skippy-agentspace
  category: utility
---

# Excalidraw Diagram Creator

Generate `.excalidraw` files via Mermaid syntax + browser conversion. Output: `~/Downloads/<name>.excalidraw` + optional PNG.

## Dependencies

- `@excalidraw/mermaid-to-excalidraw` + `mermaid` (bun packages, peer deps)
- `agent-browser` MCP (real Chromium for dagre layout -- server-side mocks produce garbage spacing)
- `claudePy` (all Python post-processing -- never `python3`)

## Architecture (CRITICAL)

**NEVER do diagram work in main context.** Every build step runs in a dedicated agent. Main context only orchestrates and validates results.

## Workflow

### Step 1: Understand the Request (main context)

Determine what to diagram. Clarify with user if needed. Decide diagram direction (`graph LR` or `graph TB`), color strategy (see `references/color-categories.md`), and output name.

### Step 2: Research (agent -- if technical diagram)

Spawn a **sonnet explore agent** to gather facts (architecture docs, inventory, memory files). Returns a summary of entities, relationships, and data flows -- NOT raw file contents.

### Step 3: Generate Mermaid Syntax (agent -- executor)

Spawn a **sonnet executor agent** to write the `.mmd` file:
- Shape mapping: `(())` external, `{}` decisions/VLANs, `[]` services, `[()]` databases
- Use `subgraph` for groupings; pack IPs/ports/descriptions into node text with `\n`
- Dashed arrows `-.->` for optional/VPN; labeled arrows `-->|label|` for data flows
- Save `.mmd` alongside the output `.excalidraw` file

### Step 4: Convert Mermaid to Excalidraw via Browser (agent -- executor)

Spawn an executor agent to run the full browser pipeline: write `browser-entry.ts`, bundle with bun, serve locally, navigate with agent-browser, wait for completion, extract JSON, kill server. Then post-process with `claudePy` (apply colors, set roughness/stroke/background).

See `references/browser-pipeline.md` for full implementation detail.

### Step 5: Render PNG (agent -- executor, optional)

Open the `.excalidraw` file in agent-browser via `references/render_template.html` and screenshot to `~/Downloads/<name>.png`.

### Step 6: Validate (main context)

View the PNG (Read tool) or have user open `.excalidraw`. If fixes needed, spawn another executor to edit the `.mmd` and re-run from Step 4.

## Output

- Default: `~/Downloads/<name>.excalidraw`
- Override with any user-specified path
- Save `.mmd` source alongside the `.excalidraw` file

## Gotchas

- `text` and `originalText` must match exactly
- Container `boundElements` <-> text `containerId` must be bidirectional
- Arrow `startBinding`/`endBinding` elementIds must reference existing shape IDs
- `seed` values must be unique per element
- Mermaid node IDs starting with numbers need quoting: `"202"[CT 202...]`
- `parseMermaidToExcalidraw` is async -- await it

## References

- `references/browser-pipeline.md` -- Browser conversion + skeleton expansion + claudePy post-processing
- `references/color-categories.md` -- Dark-infrastructure category color table + subgraph BG values
- `references/element-templates.md` -- JSON templates for shapes, arrows, text
- `references/json-schema.md` -- Excalidraw JSON format specification
- `references/render_template.html` -- HTML template for agent-browser PNG rendering
- `references/palettes/*.md` -- Named color palettes
