<!-- Extracted from SKILL.md -- load on demand -->

# Excalidraw JSON Schema

## File Structure

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "pai-excalidraw-skill",
  "elements": [ ... ],
  "appState": {
    "viewBackgroundColor": "#ffffff"
  },
  "files": {}
}
```

## Element Types

| Type | Use For |
|------|---------|
| `rectangle` | Processes, actions, components |
| `ellipse` | Entry/exit points, external systems |
| `diamond` | Decisions, conditionals |
| `arrow` | Connections between shapes |
| `text` | Labels (free-floating or inside shapes) |
| `line` | Non-arrow connections, structural lines |
| `frame` | Grouping containers |

## Common Properties (all elements)

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique identifier -- use descriptive names |
| `type` | string | Element type |
| `x`, `y` | number | Position in pixels |
| `width`, `height` | number | Size in pixels |
| `strokeColor` | string | Border color (hex) |
| `backgroundColor` | string | Fill color (hex or "transparent") |
| `fillStyle` | string | "solid", "hachure", "cross-hatch" |
| `strokeWidth` | number | 1 (thin), 2 (standard), 3+ (bold) |
| `strokeStyle` | string | "solid", "dashed", "dotted" |
| `roughness` | number | 0 (clean/modern), 1 (sketchy), 2 (rough) |
| `opacity` | number | 0-100 (always use 100) |
| `seed` | number | Random seed -- must be unique per element |
| `version` | number | Usually 1 |
| `versionNonce` | number | Usually different from seed |
| `isDeleted` | boolean | false |
| `groupIds` | array | Group membership |
| `boundElements` | array/null | Elements bound to this one |
| `link` | string/null | URL link |
| `locked` | boolean | false |
| `angle` | number | Rotation in radians (usually 0) |

## Text-Specific Properties

| Property | Description |
|----------|-------------|
| `text` | The display text |
| `originalText` | Must match `text` exactly |
| `fontSize` | Size in pixels (16-20 recommended) |
| `fontFamily` | 1 (Virgil/hand), 2 (Helvetica), 3 (Cascadia/mono) |
| `textAlign` | "left", "center", "right" |
| `verticalAlign` | "top", "middle", "bottom" |
| `containerId` | ID of parent shape (null if free-floating) |
| `lineHeight` | Usually 1.25 |

## Arrow-Specific Properties

| Property | Description |
|----------|-------------|
| `points` | Array of [x, y] coordinates relative to element x,y |
| `startBinding` | Connection to start shape |
| `endBinding` | Connection to end shape |
| `startArrowhead` | null, "arrow", "bar", "dot", "triangle" |
| `endArrowhead` | null, "arrow", "bar", "dot", "triangle" |

## Binding Format

```json
{
  "elementId": "target-shape-id",
  "focus": 0,
  "gap": 2
}
```

- `focus`: -1 to 1, controls where arrow connects on shape edge (0 = center)
- `gap`: pixels between arrow tip and shape edge

## Roundness (for rectangles)

```json
"roundness": { "type": 3 }
```

Omit for sharp corners.

## Dark Background Diagrams

Set in appState:
```json
"appState": {
  "viewBackgroundColor": "#1a1a2e"
}
```

Adjust text colors to light values when using dark backgrounds.
