# Setup Workflow

Initialize auto-documentation for current TypeScript project.

## Steps

1. **Verify TypeScript library project**
   - Must have package.json
   - Must have index.ts or lib/index.ts or src/index.ts

2. **Create README.template.md**
   ```bash
   cp README.md README.template.md
   ```

3. **Add API markers to README.template.md**
   Add these lines where you want API docs:
   ```markdown
   ## API Reference
   <!-- API START -->
   <!-- API END -->
   ```

4. **Generate initial docs**
   ```bash
   auto-docs-generate
   ```

5. **Verify**
   ```bash
   git diff README.md  # Should see generated API docs
   ```

6. **Commit**
   ```bash
   git add README.template.md README.md
   git commit -m "docs: setup auto-docs"
   ```

## What Happens Next

Every commit will auto-check if README.md matches TSDoc:
- If in sync → commit allowed
- If out of sync → commit blocked, README.md regenerated, you stage and retry

No setup needed - global git hook handles it.
