# Status Workflow

Check if auto-docs is working in current project.

## Checks

1. **Is TS library project?**
   ```bash
   test -f index.ts && echo "✅" || echo "❌"
   ```

2. **Has README.template.md?**
   ```bash
   test -f README.template.md && echo "✅" || echo "❌"
   ```

3. **Has API markers?**
   ```bash
   grep -q "<!-- API START -->" README.template.md && echo "✅" || echo "❌"
   ```

4. **Docs in sync?**
   ```bash
   auto-docs-generate --check && echo "✅" || echo "❌"
   ```

5. **Global hook installed?**
   ```bash
   test -x ~/.config/git/hooks/pre-commit && echo "✅" || echo "❌"
   ```
