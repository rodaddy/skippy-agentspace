<!-- Extracted from SKILL.md -- load on demand -->

# Autoresearch Phases -- Detailed Reference

## Phase 1: Discovery -- Templates

### For Repo Targets

```
Repo: [name]
Stack: [languages, frameworks]
Purpose: [one sentence]
Quality tools found: [list]
```

Steps:
1. Use qmd to query the codebase structure
2. Read key config files (package.json, pyproject.toml, tsconfig.json, etc.)
3. Sample 3-5 source files from main code directories
4. Identify: languages, frameworks, purpose, existing quality tools

### For Skill/Hook Targets

```
Skill: [name]
Purpose: [one sentence]
Trigger description: [current text]
Hook dependencies: [which hooks reference this skill]
Known issues: [from skill-qa gap report, if available]
```

Steps:
1. Read the SKILL.md frontmatter and body
2. Check if any hooks reference this skill (grep settings.json)
3. Check skill-qa gap report if available at `.skill-qa/gaps.json`
4. Identify: trigger coverage, content quality, enforcement gaps

---

## Phase 2: Target Selection -- Templates

### User-First Template

```
Here is your optimization template:

  Target:  _______________________________________________
  (What do you want to improve? Pick something measurable.)

  Scope:   _______________________________________________
  (Which specific part? Narrow it down.)

  Context: _______________________________________________
  (Constraints, conventions, product-specific details.)

Examples:
  Target:  skill triggers        | hook enforcement        | test coverage
  Scope:   n8n skill only        | LAW 5 pre-impl hook     | auth module
  Context: triggers too narrow   | false positive rate high | pytest + factory_boy

What do you want to optimize? Fill in the fields above.
If nothing comes to mind, say "suggest" for ideas.
```

### Universal Quality Dimensions (for suggestions)

Scan target against each, generate 1-2 suggestions per relevant dimension:

- **Correctness** -- error handling, edge cases, input validation
- **Testing** -- coverage gaps, test quality, assertion patterns
- **Performance** -- efficiency, caching, resource usage
- **Security** -- secret handling, input sanitization, auth patterns
- **Maintainability** -- naming, modularity, coupling, dead code
- **Observability** -- logging, metrics, tracing, error reporting
- **Reliability** -- failure handling, retries, graceful degradation
- **Developer experience** -- API ergonomics, config patterns, convention consistency
- **Compliance** -- accessibility, i18n, coding standards

For skills specifically, add:
- **Trigger accuracy** -- does the description match natural language requests?
- **Content quality** -- is the skill useful enough that manual work isn't easier?
- **Hook coverage** -- are violations actually caught?

---

## Phase 3: Metric Definition -- Process

1. For the chosen target, generate 4-6 binary eval criteria
2. Tag each as `command` or `agent-judge`
3. Prefer `command` where reliable programmatic checks exist
4. Present to user for approval

### Presentation Format

```
Eval criteria for [target] (N items x M criteria = max score NxM):

1. [criterion] -- yes/no -- [agent-judge | command: <cmd>]
2. [criterion] -- yes/no -- [agent-judge | command: <cmd>]
3. [criterion] -- yes/no -- [agent-judge | command: <cmd>]
4. [criterion] -- yes/no -- [agent-judge | command: <cmd>]

These are the metrics I'll evaluate against. Want to adjust any, or good to go?
```

---

## Phase 4: Baseline -- Setup Checklist

1. Choose batch size based on output complexity
2. Create `.autoresearch/` with:
   - `prompt.txt` (initial prompt)
   - `best_prompt.txt` (copy of initial)
   - `state.json` (see state-format.md)
   - `results.jsonl` (empty)
3. Select 3-5 validation items spanning different difficulty levels
4. Add `.autoresearch/` to `.gitignore`
5. Run 1 cycle to establish baseline
6. Report baseline score and per-criterion breakdown

---

## Phase 5: Loop -- Cycle Report Format

```
RUN [n] | Score: [score]/[max] | Validation: [v_score]/[v_max] | Status: [KEEP/DISCARD] | Best: [best]/[max]
  [criterion 1]: [count]/[N]
  [criterion 2]: [count]/[N]
  ...
  Mutation: [operator used]
  [Top failures: brief list]
  [Item flags: if any]
```

### Criteria Health Check (at Run 10)

Re-read full results.jsonl and review:
- **Too easy**: 100% pass rate since run 1 -- suggest replacing
- **Too hard**: never exceeded 20% -- may need rewording or code changes
- Do NOT pause loop for flags -- log and keep running

### Final Summary Format

```
AUTORESEARCH COMPLETE
  Runs: [total]
  Starting score: [baseline]/[max]
  Final best score: [best]/[max]
  Improvement: [percentage]%
  Runs kept: [count]
  Most effective mutation operators: [ranked by KEEP rate]

Best prompt saved to: .autoresearch/best_prompt.txt
Full history: .autoresearch/results.jsonl
```
