# Browser Pipeline -- Implementation Detail

Full implementation guide for Step 4 (browser conversion) and Step 4b (post-processing) of the excalidraw skill.

## Why Browser

Mermaid requires real SVG `getBBox()` for dagre layout. happy-dom/jsdom produce broken spacing. Real Chromium via agent-browser MCP gives pixel-perfect layout.

## Step 4: Convert Mermaid via Browser

The executor agent must complete the following in sequence:

### 1. Write `browser-entry.ts`

```ts
import { parseMermaidToExcalidraw } from "@excalidraw/mermaid-to-excalidraw";

window.__runConvert = async (mermaidText: string) => {
  try {
    const { elements, files } = await parseMermaidToExcalidraw(mermaidText);
    const expanded = expandSkeletons(elements);
    window.__result = JSON.stringify({ elements: expanded, files });
    document.getElementById("status").textContent = "DONE";
  } catch (e) {
    document.getElementById("status").textContent = "ERROR: " + e.message;
  }
};
```

### 2. Bundle

```bash
bun build browser-entry.ts --target browser --bundle --outfile dist/bundle.js
```

### 3. Write `dist/index.html`

Minimal HTML that loads `bundle.js` and calls `window.__runConvert(mermaidText)`. Include a `<div id="status"></div>` element.

### 4. Serve locally

```bash
bun --hot dist/
# or: bunx serve dist/ -p <free-port>
```

Pick any free port (e.g. 3456).

### 5. Navigate and wait

```
browser_navigate → http://localhost:<port>/
browser_wait     → element #status contains "DONE" (or "ERROR")
```

### 6. Extract result

```
browser_eval("window.__result")
```

Returns the Excalidraw JSON string.

### 7. Kill server

Kill the local server process after extraction.

---

## Skeleton Expansion Logic

`parseMermaidToExcalidraw` returns skeleton elements with a `label` property instead of proper bound text elements. You **must** expand these manually inside `browser-entry.ts`.

### Containers (rectangle / ellipse / diamond)

For each shape element with a `label`:
- Strip the `label` property from the container
- Add `boundElements: [{ type: "text", id: textId }]` to the container
- Emit a separate text element with:
  - `id`: `text_<containerId>_<counter>` (unique string)
  - `containerId`: container's ID
  - `text` and `originalText`: both set to the label string (must match exactly)
  - `seed`: unique integer per element

### Arrows with labels

For each arrow element with a `label`:
- Strip the `label` from the arrow
- Emit a floating text element near the arrow midpoint
- Same `text`/`originalText` matching rules apply

### ID and seed requirements

- IDs: unique strings, e.g. `text_<containerId>_<counter>`
- Seeds: unique integers per element -- never reuse across elements
- Container `boundElements` <-> text `containerId` must be bidirectional

---

## Step 4b: Post-Processing with claudePy

After extracting the raw JSON from the browser, run `claudePy` to finalize styling.

### Operations (in order)

1. **Color coding** -- Apply category colors by functional group. See `references/color-categories.md` for the full table and subgraph background values.

2. **Roughness + stroke** -- Set on all shape elements:
   ```python
   element["roughness"] = 0
   element["strokeWidth"] = 2  # or 3 for emphasis
   ```

3. **Background** -- Set app state:
   ```python
   data["appState"]["viewBackgroundColor"] = "#0d1117"
   ```

4. **Write output** -- Write final JSON to `~/Downloads/<name>.excalidraw`.

### claudePy invocation pattern

```bash
claudePy -c "
import json, sys
data = json.loads(open('/tmp/raw.json').read())
# ... apply transformations ...
open('/tmp/output.excalidraw', 'w').write(json.dumps(data, indent=2))
"
```

Never use `python3` directly -- always `claudePy`.
