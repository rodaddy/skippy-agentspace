# DeepDive Workflow

Comprehensive research on a technical topic with structured output and source tracking.

## When to Use

- User asks to "research [topic]", "deep dive into [subject]"
- Need comprehensive understanding of a technology
- Investigating complex technical concepts

## Process

1. **Define Scope**
   - Clarify research question
   - Identify key areas to investigate
   - Set depth level (overview vs comprehensive)

2. **Gather Sources**
   - Official documentation
   - Technical blogs and articles
   - Research papers (if applicable)
   - Community discussions (Reddit, HN, forums)
   - GitHub repositories

3. **Research Methods**
   - **Web Search:** Use WebSearch for current information
   - **Context7:** Query library-specific documentation
   - **WebFetch:** Retrieve specific URLs
   - **Code Analysis:** Read relevant open-source implementations

4. **Process Information**
   - Use fabric patterns for analysis:
     - `extract_wisdom` - Pull key insights from sources
     - `analyze_paper` - For academic sources
     - `summarize` - Condense lengthy content

5. **Structure Findings**
   ```markdown
   # Research: [Topic]

   ## Executive Summary
   [2-3 sentences: what it is, why it matters]

   ## What Is It?
   [Technical explanation]

   ## How It Works
   [Architecture/mechanisms]

   ## Use Cases
   [When to use, when not to use]

   ## Pros & Cons
   **Advantages:**
   - Pro 1
   - Pro 2

   **Disadvantages:**
   - Con 1
   - Con 2

   ## Implementation Examples
   [Code snippets or references]

   ## Sources
   1. [Official Docs](URL) - accessed DATE
   2. [Technical Article](URL) - accessed DATE
   3. [GitHub Repo](URL) - accessed DATE

   ## Recommendations
   [Actionable next steps based on research]

   ## Further Reading
   [Additional resources for deeper exploration]
   ```

6. **Present Results**
   - Provide structured report
   - Highlight key findings
   - Offer to dive deeper into specific areas

## Example Usage

**Topic: "Research how Bun's bundler works"**

1. Search for official Bun documentation
2. Find technical deep-dives and blog posts
3. Review Bun's GitHub repository
4. Extract wisdom from sources
5. Compare with other bundlers (webpack, esbuild)
6. Structure findings with sources

**Output:**
```markdown
# Research: Bun's Bundler Architecture

## Executive Summary
Bun's bundler is a built-in, zero-config bundler written in Zig that
achieves 100x+ speed improvements over webpack through native code
execution and aggressive parallelization.

## How It Works
[Technical details about architecture]

## Comparison with Other Bundlers
| Feature | Bun | webpack | esbuild |
|---------|-----|---------|---------|
| Speed | 100x | 1x | 10x |
[...]

## Sources
1. [Bun Documentation](https://bun.sh/docs/bundler) - 2025-12-29
2. [Jarred Sumner's Blog](URL) - 2025-11-15
[...]
```

## Tips

- **Track dates** - Technical information ages quickly
- **Verify sources** - Prefer official docs over random blogs
- **Note version numbers** - APIs and features change
- **Include examples** - Practical code snippets help understanding
- **Update regularly** - Technology evolves; research has shelf life
