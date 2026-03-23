---
name: ubiquitous-language
description: Create and maintain a project glossary (GLOSSARY.md) so humans and AI share precise domain terminology. USE WHEN starting a domain-heavy project, encountering ambiguous terms, user says "glossary", "define terms", "ubiquitous language", or when miscommunication stems from undefined vocabulary.
allowed-tools: "Read,Write,Edit,Grep,Glob"
metadata:
  version: 0.1.0
  author: Rico
  category: workflow
---

# Ubiquitous Language -- Shared Domain Glossary

Maintain a project-level glossary so humans and AI agents use the same terms with the same meaning.
Based on Domain-Driven Design's ubiquitous language pattern.

## Why This Matters

When you say "alert" and the AI thinks "notification," you get wrong code.
When "user" means both "API consumer" and "end customer," bugs hide in the ambiguity.
A shared glossary eliminates this class of miscommunication entirely.

## Trigger

- `/ubiquitous-language` or `/glossary` -- create or update the project glossary
- `/glossary add <term>` -- add a term interactively
- `/glossary check` -- scan recent conversation for undefined terms

## File Location

`GLOSSARY.md` in the project root, next to CLAUDE.md.

## Format

```markdown
# Glossary

Project-specific terminology. All agents and contributors use these definitions.

## Domain Terms

| Term | Definition | NOT This |
|------|-----------|----------|
| **Alert Rule** | A user-defined threshold on a commodity price that triggers a notification | Not the notification itself |
| **Commodity** | A tradeable raw material tracked in the system (corn, wheat, oil) | Not a financial derivative |
| **Position** | A user's current holdings of a commodity (quantity + avg price) | Not a geographic location |

## Technical Terms

| Term | Definition | NOT This |
|------|-----------|----------|
| **Pipeline** | The n8n workflow that processes market data | Not a CI/CD pipeline |
| **Worker** | Background job processor for alert evaluation | Not a web worker or service worker |

## Abbreviations

| Abbrev | Expansion |
|--------|-----------|
| **CPC** | Commodities Price Checker |
| **HITL** | Human In The Loop |
```

### Column Explanation

- **Term:** The word as used in this project (bold)
- **Definition:** What it means HERE, not what it means in general
- **NOT This:** Common misinterpretation to prevent. This column is what makes the glossary actually useful -- it disambiguates.

## Workflow

### Creating a New Glossary

1. Ask the user about the project domain via AskUserQuestion
2. Identify terms that have project-specific meaning
3. For each term, ask: "What does [term] mean in YOUR system?" and "What does it NOT mean?"
4. Write `GLOSSARY.md` using the format above
5. Split into Domain Terms, Technical Terms, and Abbreviations sections

### Adding Terms Mid-Session

When a new term comes up during development:

1. Notice the term is ambiguous or undefined
2. Ask the user for the project-specific definition
3. Append to GLOSSARY.md
4. Continue with the now-clarified meaning

### Checking for Undefined Terms

Scan the conversation or codebase for terms that:
- Appear frequently but aren't in the glossary
- Have multiple apparent meanings in different contexts
- Are abbreviations without expansion

Present candidates to the user for definition.

## Integration With Other Skills

- **`/prd`** -- reference GLOSSARY.md during Phase 0 (Clarification Gate). New terms discovered during PRD interviews get added to the glossary.
- **`/prd-to-issues`** -- issue descriptions use glossary terms. If a term isn't in the glossary, it shouldn't be in an issue without definition.
- **Agent prompts** -- when spawning agents for a project with a GLOSSARY.md, include relevant terms in the agent prompt so they use correct vocabulary.

## Rules

1. **Definitions are project-scoped** -- "Pipeline" means whatever it means in THIS project, not in general
2. **"NOT This" is mandatory** for any term that could be misinterpreted -- skip only for truly unambiguous terms
3. **Update immediately** when a term's meaning changes or a new term emerges
4. **No essays** -- definitions are one sentence. If you need more, the term is probably compound and should be split.
5. **Alphabetical within sections** -- makes scanning fast

## What This Skill Does NOT Do

1. **Replace documentation** -- the glossary defines terms, it doesn't explain architecture
2. **Auto-detect terms** -- it assists, but the user decides what's glossary-worthy
3. **Enforce usage** -- it doesn't lint code for wrong terminology (yet)
