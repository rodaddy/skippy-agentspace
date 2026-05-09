# LoadKB - Load Code Knowledge Base Workflow

**Purpose:** Load indexed code KB into session context to provide architecture awareness before working on repository code.

**Triggers:**
- `/load-kb`
- `/load-kb {repo-name}`
- "load kb for {repo}"
- "load knowledge base"

---

## Workflow Steps

### Step 1: Determine Repository Name

**If repo name provided as argument:**
```
User: /load-kb homelab-media-automation
→ Use: homelab-media-automation
```

**If no argument (auto-detect from CWD):**
```bash
# Extract repo name from current working directory
basename "$PWD"
```

**Examples:**
- CWD: `<DEV_DIR>/homelab-media-automation` → `homelab-media-automation`
- CWD: `~/Development/ai-second-brain` → `ai-second-brain`
- CWD: `~/code/my-project` → `my-project`

### Step 2: Check if KB Exists

**KB file path pattern:**
```
~/.config/pai-private/knowledge/code/{repo-name}/architecture-v2.json
```

**Check existence:**
```bash
KB_PATH="$HOME/.config/pai-private/knowledge/code/${REPO_NAME}/architecture-v2.json"

if [ -f "$KB_PATH" ]; then
  # KB exists - proceed to Step 3
else
  # KB not found - show error and extraction instructions
fi
```

**If KB not found:**
```
❌ No KB found for: {repo-name}

Available indexed repos:
{list ~/.config/pai-private/knowledge/code/*/}

To create KB:
bun Tools/code-kb-extract-v2.ts /path/to/{repo-name}
```

### Step 3: Read KB File

**Use Read tool to load KB:**
```
Read ~/.config/pai-private/knowledge/code/{repo-name}/architecture-v2.json
```

**Parse JSON structure:**
```json
{
  "repositoryName": "string",
  "metadata": {
    "primaryLanguage": "string",
    "frameworks": ["array"],
    "tags": ["array"]
  },
  "architectureDecisions": [{"objects"}],
  "designPatterns": [{"objects"}],
  "integrations": [{"objects"}],
  "antiPatterns": [{"objects"}],
  "bestPractices": [{"objects"}],
  "insights": ["strings"]
}
```

### Step 4: Present Summary

**Format:**
```
✅ Loaded {repo-name} KB

📊 Architecture Context:
   Language: {primaryLanguage}
   Frameworks: {frameworks[]}

   Architecture Decisions: {count} ({CRITICAL/HIGH/MEDIUM breakdown})
   Design Patterns: {count}
   Integrations: {count}
   Anti-Patterns: {count}
   Best Practices: {count}

🔑 Key Insights:
   - {insight 1}
   - {insight 2}
   - {insight 3}

💡 Context loaded and available for this session.
```

**Example output:**
```
✅ Loaded homelab-media-automation KB

📊 Architecture Context:
   Language: Python
   Frameworks: Flask

   Architecture Decisions: 7 (3 CRITICAL, 3 HIGH, 1 MEDIUM)
   Design Patterns: 4
   Integrations: 3 (Plex, yt-dlp, TrueNAS)
   Anti-Patterns: 1
   Best Practices: 1

🔑 Key Insights:
   - MCP server integration for Claude Code automation
   - Ansible-based infrastructure deployment
   - Network-level VPN enforcement via UniFi gateway

💡 Context loaded and available for this session.
```

### Step 5: Store Context Awareness

**Set session variable (mental note for AI):**
```
LOADED_KB={repo-name}
KB_CONTEXT={full JSON object}
```

**AI should now:**
- Reference architecture decisions when making code changes
- Follow design patterns already established in repo
- Respect integration patterns when adding new integrations
- Avoid anti-patterns documented in KB
- Apply best practices from KB

---

## Implementation Details

### Auto-Detection Logic

**Repo name extraction from CWD:**
```typescript
const cwd = process.cwd();
const repoName = cwd.split('/').pop(); // Last segment of path

// Example:
// <DEV_DIR>/homelab-media-automation
//   → homelab-media-automation
```

**Handle edge cases:**
- CWD is home directory → Error: "Not in a repository directory"
- CWD is root (/) → Error: "Cannot auto-detect repo from root"
- CWD is subdirectory of repo → Extract parent repo name (optional enhancement)

### Summary Generation

**Count items by category:**
```typescript
const summary = {
  decisions: kb.architectureDecisions.length,
  patterns: kb.designPatterns.length,
  integrations: kb.integrations.length,
  antiPatterns: kb.antiPatterns.length,
  bestPractices: kb.bestPractices.length
};
```

**Impact breakdown (for decisions):**
```typescript
const impactCounts = {
  CRITICAL: kb.architectureDecisions.filter(d => d.impact === 'CRITICAL').length,
  HIGH: kb.architectureDecisions.filter(d => d.impact === 'HIGH').length,
  MEDIUM: kb.architectureDecisions.filter(d => d.impact === 'MEDIUM').length
};
```

**Integration names:**
```typescript
const integrationNames = kb.integrations.map(i => i.title).join(', ');
```

### Context Retention

**For rest of session, AI should:**
1. Remember KB is loaded (don't reload unnecessarily)
2. Reference specific decisions when relevant:
   - "Per architecture decision #3 (VPN enforcement)..."
   - "Following the retry-backoff pattern from KB..."
3. Cite anti-patterns when preventing mistakes:
   - "KB warns against direct API calls - using cache instead"
4. Apply best practices proactively:
   - "Using AsyncMock for testing per KB best practices"

---

## Error Handling

### Error: Repo Name Ambiguous

**Problem:** Multiple repos with similar names in KB directory

**Solution:**
```
⚠️ Multiple matches found:
   - homelab-media-automation
   - homelab-media-automation-old

Which repo? /load-kb {exact-name}
```

### Error: KB File Corrupted

**Problem:** JSON parse error when reading KB

**Solution:**
```
❌ KB file corrupted: {repo-name}
   File: {path}
   Error: {parse error}

Re-extract KB:
bun Tools/code-kb-extract-v2.ts /path/to/{repo-name}
```

### Error: Not in Git Repo

**Problem:** CWD is not a repository (no auto-detect possible)

**Solution:**
```
⚠️ Cannot auto-detect repo from: {cwd}

Available indexed repos:
{list available KBs}

Load specific repo:
/load-kb {repo-name}
```

---

## Advanced Usage

### Load Multiple Repos

**If working across repos:**
```
/load-kb homelab-media-automation
/load-kb ai-second-brain
```

**AI context now includes both KBs:**
- Can compare architecture patterns
- Can reference cross-repo integrations
- Can apply best practices from one to another

**Caveat:** Context usage increases proportionally (40KB × N repos)

### Reload KB After Extraction

**If KB was updated:**
```
# Re-extract KB
bun Tools/code-kb-extract-v2.ts /path/to/repo

# Reload in session
/load-kb repo-name
```

**AI should:**
- Overwrite previous KB context
- Note any changes (new decisions, patterns, etc.)
- Update mental model of architecture

---

## Success Criteria

**Skill execution successful if:**
- ✅ KB file found and read successfully
- ✅ JSON parsed without errors
- ✅ Summary shown with counts and key info
- ✅ AI can reference KB content in subsequent responses
- ✅ No duplicate loading (check if already loaded)

**Quality indicators:**
- Summary is concise (< 10 lines)
- Key insights surfaced (top 3-5)
- Integration names listed
- Impact breakdown for critical decisions
- AI actually uses KB context when coding

---

## Testing

**Test cases:**

1. **Auto-detect from CWD:**
   ```bash
   cd <DEV_DIR>/homelab-media-automation
   /load-kb
   # Should load homelab KB
   ```

2. **Explicit repo name:**
   ```bash
   /load-kb ai-second-brain
   # Should load ai-second-brain KB regardless of CWD
   ```

3. **KB not found:**
   ```bash
   /load-kb nonexistent-repo
   # Should show error + extraction instructions
   ```

4. **No argument, not in repo:**
   ```bash
   cd ~/Downloads
   /load-kb
   # Should show error + list available KBs
   ```

---

**Related Workflows:**
- `kb-extraction/ExtractCodeKB.md` - Create/update KBs
- `kb-extraction/QueryKB.md` - Search KB content
