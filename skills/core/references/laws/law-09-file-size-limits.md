# LAW 9: File Size Limits

**Enforcement:** `pre-edit-file-size.ts` (PreWrite, PreEdit hooks)
**Severity:** MANDATORY

## Rule

750 lines max per file. Split proactively at ~600 lines.

## Why

Large files are hard to navigate, slow to parse in context windows, and tend to accumulate unrelated concerns. Splitting at 600 lines gives buffer before hitting the hard limit and forces better module boundaries.

## Enforcement Details

- Pre-Write/Edit hook checks resulting file line count
- Blocks writes that would push a file over 750 lines
- Warns at 600+ lines to encourage proactive splitting

## Guidelines

1. Check line count before adding to existing files
2. Create new modules over extending large ones
3. If user says "too big" or "monolith" -- you went too far

## Examples

**Correct:** Split `api.ts` (580 lines) into `api-auth.ts` and `api-data.ts` before adding new endpoints.

**Incorrect:** Keep adding functions to a 700-line file because "it's all related."

## Exceptions

- Generated files (lock files, schemas) that can't be reasonably split
- Data files (JSON, CSV) where splitting breaks structure
