<!-- Extracted from SKILL.md -- load on demand -->

# Element Templates

Copy-paste JSON templates for each Excalidraw element type. Replace color placeholders with values from the active palette.

## Free-Floating Text (no container)
```json
{
  "type": "text",
  "id": "label-descriptive-name",
  "x": 100, "y": 100,
  "width": 200, "height": 25,
  "text": "Section Title",
  "originalText": "Section Title",
  "fontSize": 20,
  "fontFamily": 3,
  "textAlign": "left",
  "verticalAlign": "top",
  "strokeColor": "<title color from palette>",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 11111,
  "version": 1,
  "versionNonce": 22222,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "containerId": null,
  "lineHeight": 1.25
}
```

## Rectangle (process, action, component)
```json
{
  "type": "rectangle",
  "id": "rect-descriptive-name",
  "x": 100, "y": 100, "width": 180, "height": 90,
  "strokeColor": "<stroke from palette>",
  "backgroundColor": "<fill from palette>",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 12345,
  "version": 1,
  "versionNonce": 67890,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": [{"id": "text-descriptive-name", "type": "text"}],
  "link": null,
  "locked": false,
  "roundness": {"type": 3}
}
```

## Text Inside Shape (bound to container)
```json
{
  "type": "text",
  "id": "text-descriptive-name",
  "x": 130, "y": 132,
  "width": 120, "height": 25,
  "text": "Process",
  "originalText": "Process",
  "fontSize": 16,
  "fontFamily": 3,
  "textAlign": "center",
  "verticalAlign": "middle",
  "strokeColor": "<text color from palette>",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 11111,
  "version": 1,
  "versionNonce": 22222,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "containerId": "rect-descriptive-name",
  "lineHeight": 1.25
}
```

**Critical:** Container's `boundElements` must list the text ID, and text's `containerId` must reference the container ID.

## Ellipse (start/end points, external systems)
```json
{
  "type": "ellipse",
  "id": "ellipse-descriptive-name",
  "x": 100, "y": 100, "width": 120, "height": 80,
  "strokeColor": "<stroke from palette>",
  "backgroundColor": "<fill from palette>",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 55555,
  "version": 1,
  "versionNonce": 66666,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": [{"id": "text-ellipse-name", "type": "text"}],
  "link": null,
  "locked": false
}
```

## Diamond (decisions, conditionals)
```json
{
  "type": "diamond",
  "id": "decision-descriptive-name",
  "x": 100, "y": 100, "width": 140, "height": 100,
  "strokeColor": "<decision stroke from palette>",
  "backgroundColor": "<decision fill from palette>",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 77777,
  "version": 1,
  "versionNonce": 88888,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": [{"id": "text-decision-name", "type": "text"}],
  "link": null,
  "locked": false
}
```

## Arrow (connections between shapes)
```json
{
  "type": "arrow",
  "id": "arrow-source-to-target",
  "x": 282, "y": 145, "width": 118, "height": 0,
  "strokeColor": "<arrow color from palette>",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 33333,
  "version": 1,
  "versionNonce": 44444,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "points": [[0, 0], [118, 0]],
  "startBinding": {"elementId": "source-id", "focus": 0, "gap": 2},
  "endBinding": {"elementId": "target-id", "focus": 0, "gap": 2},
  "startArrowhead": null,
  "endArrowhead": "arrow"
}
```

For curved arrows, use 3+ points: `[[0,0], [60,-40], [118,0]]`

## Line (structural, non-arrow)
```json
{
  "type": "line",
  "id": "line-descriptive-name",
  "x": 100, "y": 100,
  "width": 0, "height": 200,
  "strokeColor": "<structural line color from palette>",
  "backgroundColor": "transparent",
  "fillStyle": "solid",
  "strokeWidth": 2,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 44444,
  "version": 1,
  "versionNonce": 55555,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false,
  "points": [[0, 0], [0, 200]]
}
```

## Small Marker Dot
```json
{
  "type": "ellipse",
  "id": "dot-descriptive-name",
  "x": 94, "y": 94,
  "width": 12, "height": 12,
  "strokeColor": "<marker color from palette>",
  "backgroundColor": "<marker color from palette>",
  "fillStyle": "solid",
  "strokeWidth": 1,
  "strokeStyle": "solid",
  "roughness": 0,
  "opacity": 100,
  "angle": 0,
  "seed": 66666,
  "version": 1,
  "versionNonce": 77777,
  "isDeleted": false,
  "groupIds": [],
  "boundElements": null,
  "link": null,
  "locked": false
}
```

## Size Guidelines

| Element Role | Width x Height |
|-------------|---------------|
| Hero/focal | 300 x 150 |
| Primary | 180 x 90 |
| Secondary | 120 x 60 |
| Small/marker | 60 x 40 or 10-20px dots |

## Shape Semantics

| Shape | Use For |
|-------|---------|
| No container (text only) | Labels, descriptions, annotations |
| Ellipse | Start/trigger, end/result, external systems |
| Diamond | Decisions, conditions, branches |
| Rectangle | Processes, actions, steps, components |
| Line + text | Hierarchies, trees (no boxes needed) |
