# Routing Actions Reference

## Project Todos

```
What would you like to do with: <title>

a) Work on it now
b) Add progress update
c) Defer to later
d) Drop (no longer relevant)
e) Mark completed (with notes)
```

## Global Ideas (Active)

```
What would you like to do with: <title>

a) Work on it now
b) Convert to project todo (which project?)
c) Defer to someday
d) Mark completed (with notes)
e) Drop (no longer relevant)
```

## Someday Items

```
What would you like to do with: <title>

a) Reactivate (move to active ideas)
b) Convert to project todo (which project?)
c) Drop (no longer relevant)
d) Keep in someday
```

## Action Implementation

| Action | How |
|--------|-----|
| Work on it | Read the todo file, summarize context, hand off with "Ready to start on <title>. Next steps: ..." |
| Update/Complete/Defer/Drop | Call `/update-todo` with the appropriate action |
| Convert to project todo | Create new file in target `.planning/todos/pending/`, move original to `.claude_ideas/completed/` |
| Reactivate | Move from `someday/` to `active/` |
