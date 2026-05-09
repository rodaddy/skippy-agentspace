# Tools-First Philosophy for PAI Skills

**Source:** Daniel Miessler's principle - "Anything that can be done with code should be done first as it's more deterministic, then let AI help with the rest"

**Status:** MANDATORY for all new skills created after 2025-12-29

---

## Core Principle

**DON'T:**
- ❌ Write markdown workflows with bash commands for AI to manually execute
- ❌ Trust AI to remember multi-step procedures
- ❌ Document processes that should be automated

**DO:**
- ✅ Build executable tools/scripts that do the deterministic work
- ✅ Let AI invoke the tools when triggered
- ✅ Write skills that call code, not code that AI types manually

---

## The Pattern

### Bad Approach (Old Way)

```markdown
## Workflow: Search History

**User says:** "Search my history for X"

**Steps:**
1. Run `grep -r "X" ~/.config/pai/history/`
2. Filter results by relevance
3. Present findings
```

**Problem:** AI must remember these steps, might run wrong command, inconsistent results.

### Good Approach (Tools-First)

```markdown
## Workflow: Search History

**User says:** "Search my history for X"

**Execute:**
bun ~/.config/pai/Skills/HistoryQuery/tools/search-history.ts "X"
```

```typescript
// tools/search-history.ts - DETERMINISTIC CODE
#!/usr/bin/env bun
import { execSync } from 'child_process';

const query = process.argv[2];
const results = execSync(`grep -r "${query}" ~/.config/pai/history/`);
// ... format and output
```

**Benefit:** AI just calls the tool. Tool does all the work correctly, every time.

---

## When to Build Tools

**Build executable tools when:**
1. ✅ Workflow has 3+ steps
2. ✅ Workflow requires precise bash commands
3. ✅ Workflow parses data (JSON, logs, files)
4. ✅ Workflow produces formatted output
5. ✅ Workflow might be used frequently
6. ✅ Correctness matters more than flexibility

**Skip tools when:**
1. ❌ Single simple command (e.g., "show me this file")
2. ❌ Highly variable/creative tasks (e.g., "analyze this code for patterns")
3. ❌ Truly one-off operations
4. ❌ AI judgment is the core value, not execution

---

## Directory Structure

### Minimal Skill (with tools)
```
skill-name/
├── SKILL.md                    # Routing + documentation
└── tools/
    └── main-tool.ts            # Executable script
```

### Standard Skill (with tools)
```
skill-name/
├── SKILL.md
├── workflows/                  # Markdown docs ONLY for AI guidance
│   └── when-to-use.md
└── tools/                      # EXECUTABLE SCRIPTS
    ├── tool1.ts
    ├── tool2.ts
    └── tool3.ts
```

### Complex Skill (with tools)
```
skill-name/
├── SKILL.md
├── workflows/
│   ├── overview.md
│   └── advanced-usage.md
├── tools/
│   ├── core/
│   │   ├── search.ts
│   │   └── analyze.ts
│   └── helpers/
│       └── format.ts
└── documentation/
    └── tool-api.md
```

---

## Tool Requirements

**Every tool must:**
1. ✅ Have a shebang: `#!/usr/bin/env bun` (or `#!/usr/bin/env node`, `#!/bin/bash`)
2. ✅ Be executable: `chmod +x tool-name.ts`
3. ✅ Parse arguments clearly (use `process.argv` or proper arg parser)
4. ✅ Provide usage help when called with no args or `--help`
5. ✅ Return proper exit codes (0 = success, non-zero = error)
6. ✅ Format output consistently
7. ✅ Handle errors gracefully
8. ✅ Be self-contained (minimal dependencies)

---

## Implementation Checklist

When creating a new skill:

### Step 1: Identify Deterministic Work
- [ ] List all workflows
- [ ] For each workflow, identify steps that are:
  - Repeatable (same input → same output)
  - Data processing (parsing, filtering, formatting)
  - Complex bash pipelines
  - Multi-step procedures
- [ ] Mark these for tool implementation

### Step 2: Build Tools First
- [ ] Create `tools/` directory
- [ ] Write executable scripts for deterministic work
- [ ] Test tools independently
- [ ] Add usage/help documentation
- [ ] Ensure proper error handling

### Step 3: Document Tool Usage
- [ ] Update SKILL.md with tool invocations
- [ ] Write workflow markdown that CALLS tools, not reimplements them
- [ ] Add examples showing tool usage
- [ ] Document tool parameters and options

### Step 4: Reserve Workflows for AI Guidance
- [ ] Use workflow markdown for:
  - When to use which tool
  - How to interpret tool output
  - What to do with results
  - Decision trees (if X then call tool1, else tool2)
- [ ] NOT for bash commands AI should execute manually

---

## Examples

### Example 1: HistoryQuery Skill (Reference Implementation)

**Structure:**
```
HistoryQuery/
├── SKILL.md
└── tools/
    ├── search-history.ts       # Searches all history
    ├── show-sessions.ts        # Lists recent sessions
    └── analyze-tools.ts        # Tool usage stats
```

**SKILL.md workflow:**
```markdown
### Workflow 1: Search All History

**User says:** "Search my history for X"

**Execute:**
bun ~/.config/pai/Skills/HistoryQuery/tools/search-history.ts "X" --type all
```

**Benefits:**
- AI doesn't parse JSONL manually
- AI doesn't write grep pipelines
- AI doesn't format output
- Tool handles all deterministic work
- AI just invokes and presents results

### Example 2: Art Skill (Existing Pattern)

**Structure:**
```
Art/
├── SKILL.md
├── workflows/                  # AI guidance on when to use which workflow
│   └── workflow.md
└── tools/
    └── generate-ulart-image.ts # Actual image generation
```

**SKILL.md workflow:**
```markdown
### Workflow: Generate Editorial Illustration

**Execute:**
bun ~/.config/pai/Skills/Art/tools/generate-ulart-image.ts \
  --model nano-banana-pro \
  --prompt "[DERIVED PROMPT]" \
  --size 2K \
  --aspect-ratio 1:1 \
  --output /path/to/output.png
```

**Benefits:**
- AI focuses on creative work (deriving prompt from story)
- Tool handles API calls, image generation, background removal
- Consistent quality, proper error handling
- AI can't mess up API parameters

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Manual Bash Commands

**Bad:**
```markdown
## Workflow: Analyze Logs

**Steps:**
1. Run `cat ~/.config/pai/history/raw-outputs/2025-12/*.jsonl`
2. Pipe to `jq -r '.tool_name'`
3. Sort and count with `sort | uniq -c | sort -rn`
4. Format output
```

**Good:**
```bash
#!/usr/bin/env bun
# tools/analyze-logs.ts - DOES ALL THE WORK
```

### Anti-Pattern 2: Documenting What Should Be Coded

**Bad:**
```markdown
## Formatting Rules

**When presenting results:**
1. Group by type
2. Sort chronologically
3. Add emoji indicators
4. Truncate file paths
5. Show match counts
```

**Good:**
```typescript
// tools/format-results.ts
function formatResults(results) {
  // IMPLEMENT the formatting rules in code
  // AI doesn't need to remember, just calls the function
}
```

### Anti-Pattern 3: Complex Decision Logic in Markdown

**Bad:**
```markdown
**If searching sessions:** Use `find ~/.config/pai/history/sessions`
**If searching learnings:** Use `find ~/.config/pai/history/learnings`
**If searching all:** Use `find ~/.config/pai/history`
```

**Good:**
```typescript
// tools/search.ts --type sessions|learnings|all
// Tool handles the branching logic
```

---

## Migration Guide

**For existing skills without tools:**

1. **Identify candidates:**
   ```bash
   # Find skills without tools directories
   find ~/.config/pai/Skills -name "SKILL.md" -exec dirname {} \; | \
     while read skill; do
       [ ! -d "$skill/tools" ] && echo "$skill"
     done
   ```

2. **Assess each workflow:**
   - Read workflow markdown files
   - Identify bash commands and multi-step procedures
   - Determine if deterministic enough for tooling

3. **Extract to tools:**
   - Create `tools/` directory
   - Move bash logic to executable scripts
   - Update workflow markdown to call tools
   - Test thoroughly

4. **Document:**
   - Add TOOLS-FIRST.md reference to SKILL.md
   - Update examples to show tool usage

---

## Validation

**A skill is tools-first compliant when:**
- ✅ Has `tools/` directory with executable scripts
- ✅ Workflows in SKILL.md reference tools, not manual commands
- ✅ All deterministic work is in code
- ✅ AI's role is invocation and interpretation, not execution
- ✅ Tools can be run independently outside of AI context
- ✅ Tools have usage documentation
- ✅ Tools handle their own error cases

---

## Benefits Summary

**Why tools-first?**

1. **Determinism** - Same input always produces same output
2. **Reliability** - Code doesn't forget steps or make typos
3. **Testability** - Tools can be tested independently
4. **Reusability** - Tools work in any context (not just AI)
5. **Maintainability** - Fix in one place, works everywhere
6. **Performance** - Compiled code faster than AI parsing
7. **Consistency** - Output format never varies
8. **Error Handling** - Proper error cases vs AI improvisation

---

## Exceptions

**When markdown workflows are appropriate:**

1. **Creative/analytical tasks:** "Analyze this code for security issues" - AI judgment needed
2. **Context-dependent decisions:** "Decide which approach to use based on X" - requires reasoning
3. **One-time setups:** Installation instructions that vary by environment
4. **Guidance documents:** How to think about problems, not how to execute commands
5. **Integration points:** Explaining when to call which tool, interpreting results

**Rule of thumb:** If you can write it as code with clear input/output, write it as code.

---

**Last Updated:** 2025-12-29
**Applies to:** All new skills
**Migrating:** Existing skills encouraged but not required
**Reference Implementation:** HistoryQuery skill
