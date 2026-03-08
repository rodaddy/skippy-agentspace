# Dark Infrastructure Color Categories

Default palette for technical/infrastructure diagrams. Apply by functional category.

## Node Colors

| Category | Fill | Stroke | Text |
|----------|------|--------|------|
| Network/Entry | `#0d3b66` | `#4fc3f7` | `#e0f7fa` |
| VPN/Security | `#4a1942` | `#f48fb1` | `#fce4ec` |
| Media/Content | `#3e2723` | `#ffb74d` | `#fff3e0` |
| AI/Compute | `#1a237e` | `#7c4dff` | `#ede7f6` |
| Infrastructure | `#1b5e20` | `#69f0ae` | `#e8f5e9` |
| Backup/Storage | `#b71c1c` | `#ff8a80` | `#ffebee` |
| External Entity | `#212121` | `#90a4ae` | `#eceff1` |

## Subgraph Background

Use a semi-transparent dark fill with the category's stroke color as border.
- `opacity: 20-30` on the background rectangle
- `strokeColor`: category stroke from table above
- `fillStyle: "solid"`, `backgroundColor`: category fill (darkened further if needed)
- Cluster label: bold, category text color, positioned top-center inside subgraph rect

## appState

```json
{
  "viewBackgroundColor": "#0d1117"
}
```

## Style Defaults

- `roughness: 0` -- clean modern look (no sketch effect)
- `strokeWidth: 2` for shapes, `3` for primary flow arrows
- `strokeWidth: 1` for secondary/dashed arrows
- `fontFamily: 1` (Virgil/Excalifont)
- `fontSize: 14-16` for node labels, `12` for subgraph titles
