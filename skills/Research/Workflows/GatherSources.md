# GatherSources Workflow

Collect and organize research sources (documentation, papers, articles, repos).

## When to Use

- User asks to "find sources on [topic]", "gather documentation"
- Building research foundation
- Need curated reading list

## Process

1. **Define Research Topic**
   - Clarify specific area
   - Identify relevant subtopics
   - Set scope (broad overview vs narrow focus)

2. **Source Categories**

   **Official Documentation:**
   - Primary source material
   - API references
   - Official guides and tutorials

   **Academic Sources:**
   - Research papers
   - Technical reports
   - Conference proceedings

   **Community Content:**
   - Technical blog posts
   - Community guides
   - Stack Overflow discussions

   **Code Examples:**
   - GitHub repositories
   - Code samples
   - Reference implementations

   **Media:**
   - Technical talks/presentations
   - YouTube tutorials
   - Podcasts/interviews

3. **Search Strategy**
   - **WebSearch**: For current content and community resources
   - **Context7**: For library-specific documentation
   - **GitHub search**: For code examples and repos
   - **Academic databases**: For papers (Google Scholar, arXiv)

4. **Evaluate Source Quality**
   - **Authority**: Official docs > personal blogs
   - **Recency**: Check publication dates
   - **Relevance**: Matches research scope
   - **Depth**: Appropriate detail level

5. **Organize Sources**
   ```markdown
   # Research Sources: [Topic]

   ## Official Documentation
   1. **[Source Name]**
      - URL: [link]
      - Type: Official docs
      - Date: 2025-12-29
      - Notes: [Why this is useful]

   ## Academic Papers
   1. **[Paper Title]**
      - Authors: [Names]
      - Published: [Conference/Journal, Year]
      - URL: [link]
      - Abstract: [Summary]

   ## Technical Articles
   1. **[Article Title]**
      - Author: [Name]
      - Published: [Date]
      - URL: [link]
      - Key Points: [What it covers]

   ## Code Examples
   1. **[Repo Name]**
      - URL: [GitHub link]
      - Stars: [count]
      - Last Updated: [date]
      - Description: [What it demonstrates]

   ## Videos & Talks
   1. **[Talk Title]**
      - Speaker: [Name]
      - Event: [Conference]
      - URL: [link]
      - Duration: [time]

   ## Reading Order
   For newcomers, read in this order:
   1. [Source] - Get the basics
   2. [Source] - Understand architecture
   3. [Source] - Deep dive
   [...]
   ```

6. **Annotate Sources**
   - Add context for why each source is valuable
   - Note what each covers
   - Suggest reading order
   - Flag must-read vs optional

## Example: "Gather sources on Rust's borrow checker"

```markdown
# Research Sources: Rust Borrow Checker

## Official Documentation
1. **The Rust Book - Chapter 4: Ownership**
   - URL: https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html
   - Type: Official tutorial
   - Date: 2025 (regularly updated)
   - Notes: Best starting point for understanding ownership and borrowing

2. **Rustonomicon - Advanced Ownership**
   - URL: https://doc.rust-lang.org/nomicon/
   - Type: Advanced guide
   - Notes: Deep dive into unsafe code and edge cases

## Academic Papers
1. **"Oxide: The Essence of Rust"**
   - Authors: Aaron Weiss et al.
   - Published: 2019
   - URL: https://arxiv.org/abs/1903.00982
   - Abstract: Formal model of Rust's type system

## Technical Articles
1. **"How Does Rust's Borrow Checker Work?"**
   - Author: Niko Matsakis
   - URL: [link]
   - Key Points: Polonius project, NLL improvements

## Code Examples
1. **rust-lang/rust**
   - URL: https://github.com/rust-lang/rust
   - Path: compiler/rustc_borrowck/
   - Notes: Actual borrow checker implementation

## Videos
1. **"Understanding Rust's Borrow Checker"**
   - Speaker: Jon Gjengset
   - URL: [YouTube]
   - Duration: 45 minutes

## Reading Order
1. Rust Book Ch.4 - Foundation
2. Technical article - Practical insights
3. Academic paper - Theoretical depth
4. Source code - Implementation details
```

## Tips

- **Prioritize quality over quantity** - 5 great sources > 50 mediocre ones
- **Check dates** - Old content may be outdated
- **Cross-reference** - Multiple sources confirm accuracy
- **Save for later** - Archive sources (links die)
- **Track what you've read** - Mark completed sources
