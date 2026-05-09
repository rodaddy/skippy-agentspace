# Interview Loop

**Purpose:** Run a four-phase comprehension interview on a project the user built. One question at a time, with pushback on vague answers.

**When to Use:**
- User wants to comprehension-test a specific project
- User says "interview me about X", "test my understanding of X"
- User wants to prove they understand what they built

---

## Setup

### Project Selection

If the user named a specific project, use it. If not, offer known projects:

| Project | Domain | Context Source |
|---------|--------|----------------|
| PAI Infrastructure | AI agent infra | `~/.config/pai/` |
| MyProject | Web application | `my-project/` |
| sample-app | API service | `sample-app/` |
| portfolio-site | Frontend | `portfolio-site/` |
| data-pipeline | Data automation | `data-pipeline/` |
| content-engine | Content automation | `content-engine/` |
| n8n Workflows | Workflow automation | n8n instance |

For known projects, optionally pre-load context (git log, CLAUDE.md, architecture docs) to ask sharper questions. But DO NOT feed answers to the user -- use context only to detect vagueness and probe deeper.

### Briefing

Tell the user:
- Four phases, one question at a time
- You'll push back on vague or marketing-flavored answers
- Takes 10-15 minutes of honest thinking
- Output: explanation artifact + optional resume bullets + ledger entry
- The discomfort is the feature, not a bug

---

## Phase 0: Set the Stage

Ask: **"What did you build? Give me the name, a link if you have one, and a quick description of what it does. Don't sell it to me -- just tell me what it is."**

Wait for response. Record the project name and raw description.

---

## Phase 1: What Is This?

**Goal:** Get a precise, honest, non-marketing answer to "What is this and what problem does it solve?"

**Push on:**
- Marketing language vs. reality. If they say what it "empowers" or "enables," ask what it literally does when someone uses it.
- Scope clarity. What does it actually do vs. what they wish it did or plan to add?
- Problem specificity. "Who has this problem?" and "How did they solve it before this existed?"

**Follow-up triggers:**
- Buzzword-heavy answer -> "Strip the buzzwords. If you were explaining this to someone who's never seen it, what does it literally do?"
- Vague scope -> "Where does this project end and other tools begin? What's NOT this project's job?"
- No clear problem -> "If this project disappeared tomorrow, what specifically would break for someone?"

**Ask 1-3 follow-ups.** When you have a clear, specific answer, confirm back in plain language. Ask if that's accurate. Then move on.

**Track:** Number of pushback follow-ups required (0-3). This feeds the confidence score.

---

## Phase 2: Why This Approach?

**Goal:** Surface the decisions behind the implementation. Alternatives considered, tradeoffs evaluated, scope deliberately excluded.

**Ask:** "Walk me through why you built it this way. What were the alternatives, and why did you choose this path over those?"

**Push on:**
- Alternatives they considered -- or didn't. "This was the obvious way" -> "What would the non-obvious way have been?"
- AI contributions vs. their decisions. Where did the AI suggest something they accepted? Where did they override it, and why?
- What they deliberately chose NOT to build. Scope decisions reveal taste.
- Tradeoffs. Speed vs. quality, simplicity vs. flexibility, build vs. buy.

**Follow-up triggers:**
- No alternatives mentioned -> "Every design is a choice between options. What else could you have done here?"
- Can't articulate AI vs. own decisions -> "Walk me through a specific moment where you disagreed with what the AI suggested. What did it want to do, and what did you do instead?"
- No tradeoffs -> "What did you sacrifice to get what you have? Nothing is free."

**Ask 2-4 follow-ups.** When you can see the reasoning behind the choices, confirm and move on.

**Track:** Number of pushback follow-ups required.

---

## Phase 3: What Would Break?

**THIS IS THE HARDEST PHASE. This is where comprehension gaps become visible.**

**Ask:** "Where is this fragile? If something goes wrong, or if the requirements change, what breaks first?"

**Push on:**
- Dependencies and assumptions. What is this built on top of that they don't control?
- Edge cases. What happens with unexpected input, high load, or an unusual user?
- "What if" scenarios. What if the API they depend on changes? What if the dataset is wrong? What if a user does the thing they didn't design for?
- Honest gaps. What parts do they understand least well? Where would they struggle debugging without AI?

**Follow-up triggers:**
- "Nothing would break" or "It's pretty solid" -> DO NOT ACCEPT THIS. "Everything has fragile points. Let's find yours. What's the one dependency that, if it changed tomorrow, would require the most rework?"
- Surface-level answers -> "You described what would happen. I'm asking why it would happen and what the blast radius would be."
- Can't identify own knowledge gaps -> "If I dropped you into a debugging session on this project right now with no AI tools, which part of the codebase would make you the most nervous?"

**Ask 2-4 follow-ups.** Be relentless here. This phase separates people who understand their systems from people who happen to have working systems.

**Track:** Number of pushback follow-ups required. High pushback count here is common and important to record.

---

## Phase 4: What Did I Learn?

**Goal:** Concrete discoveries that changed how they think. Not lessons in the abstract.

**Ask:** "What did you discover during this process that changed how you think? Not lessons in the abstract -- concrete things you ran into that shifted your approach."

**Push on:**
- Moments the AI was confidently wrong and how they caught it
- Assumptions they started with that turned out to be false
- Skills or concepts they had to learn mid-project
- What they'd do differently starting over tomorrow, and why
- How this project changed what they'll build next

**Follow-up triggers:**
- Generic lessons ("I learned a lot about React") -> "What specifically about React surprised you? What did you think was true going in that turned out to be wrong?"
- No AI failure stories -> "You used AI tools on this. When was the AI most confidently wrong, and how did you catch it?"
- No false assumptions -> "What was your plan on day one, and how much of it survived contact with reality?"

**Ask 1-3 follow-ups.** Look for genuine cognitive change, not platitudes.

**Track:** Number of pushback follow-ups required.

---

## Post-Interview

After all four phases:

1. **Announce completion:** "I have what I need. Let me assemble your explanation artifact."
2. **Route to generate-artifact.md** -- assemble the polished artifact
3. **Ask:** "Want me to also generate resume bullets and update your comprehension ledger?"
   - If yes to bullets -> route to generate-bullets.md
   - If yes to ledger -> route to update-ledger.md (auto-calculates confidence from pushback counts)

---

## Confidence Scoring

Per-section confidence is calculated from pushback count:

| Pushbacks | Confidence | Meaning |
|-----------|------------|---------|
| 0 | 5 | Nailed it -- clear, specific, no hand-waving |
| 1 | 4 | Good understanding, minor clarification needed |
| 2 | 3 | Adequate but gaps visible |
| 3 | 2 | Significant gaps, struggled to articulate |
| 4+ | 1 | Does not understand this dimension well |

Overall confidence = average of four section scores, rounded.

---

## Tone

- Direct, warm, genuinely curious -- not adversarial
- The best kind of mentor: asks the question behind the question
- When someone says "it just works," ask what "works" means specifically
- When someone says "I chose X," ask what they chose it over and why
- When someone says "nothing would break," help them find their fragile points
- Name gaps honestly and gently: "It sounds like this is a part you haven't fully mapped out yet. That's useful to know -- let's note it honestly rather than hand-wave."

---

**Last Updated:** 2026-04-20
