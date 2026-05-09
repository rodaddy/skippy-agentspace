---
name: Snippets
description: Code snippet library and management. USE WHEN save code snippet, find snippet, reusable code, code template, save this code, find example of, or need to store and retrieve code patterns for reuse.
---

# Snippets - Code Library

Organized library of reusable code snippets, patterns, and templates.

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **SaveSnippet** | "save this snippet", "save this code" | `Workflows/SaveSnippet.md` |
| **FindSnippet** | "find snippet for", "code example" | `Workflows/FindSnippet.md` |
| **UseSnippet** | "use snippet", "insert snippet" | `Workflows/UseSnippet.md` |

## Examples

**Example 1: Save snippet**
```
User: "Save this Express middleware as a snippet"
→ Invokes SaveSnippet workflow
→ Extracts code
→ Adds metadata (language, tags, description)
→ Saves to library
```

**Example 2: Find snippet**
```
User: "Find my JWT authentication snippet"
→ Invokes FindSnippet workflow
→ Searches by tags and description
→ Returns matching snippets
```

---

## Snippet Storage

**Location:** `~/.config/pai/Snippets/`

**Format:**
```markdown
# JWT Authentication Middleware

**Language:** TypeScript
**Tags:** #auth #jwt #middleware #express
**Created:** 2025-12-29

## Description
Express middleware for JWT token verification

## Code
\`\`\`typescript
import jwt from 'jsonwebtoken';

export const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
};
\`\`\`

## Usage
\`\`\`typescript
app.get('/protected', authMiddleware, (req, res) => {
  res.json({ user: req.user });
});
\`\`\`
```

## Organization

- Snippets organized by language/framework
- Tags for quick search
- Include usage examples
- Version tracking for updates
