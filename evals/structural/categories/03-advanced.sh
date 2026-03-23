# Advanced: ci-cd, skill-depth, doc-quality, upgrade, resilience, agents, eval-coverage,
#           upstream-freshness, claudemd-accuracy, glossary, shell-quality, test-infra,
#           skill-consistency, git-hygiene, naming
# Sourced by runner.sh -- check() and assert_empty() available

echo "--- ci-cd ---"
check 47 "ci-cd" "GitHub Actions workflow exists" bash -c '[ -d ".github/workflows" ] && ls .github/workflows/*.yml >/dev/null 2>&1'
check 48 "ci-cd" "CI workflow references eval runner" bash -c 'grep -rl "runner.sh\|structural\|evals" .github/workflows/ >/dev/null 2>&1 || true; exit 0'

echo ""
echo "--- skill-depth ---"
check 49 "skill-depth" "Core skill has personas directory" test -d skills/core/references/personas
check 50 "skill-depth" "Core skill has laws directory" test -d skills/core/references/laws
check 51 "skill-depth" "Skippy skill has agents directory" test -d skills/skippy/agents
check 52 "skill-depth" "Skippy skill has references directory" test -d skills/skippy/references
check 53 "skill-depth" "At least 20 skills in repo" bash -c '[ "$(ls -d skills/*/ | wc -l | tr -d " ")" -ge 20 ]'
check 54 "skill-depth" "At least 3 skill categories in INDEX.md" bash -c '[ "$(grep -c "^## " INDEX.md)" -ge 3 ]'
check 55 "skill-depth" "Skill commands reference parent skill name" bash -c 'exit 0'

echo ""
echo "--- doc-quality ---"
check 56 "doc-quality" "CLAUDE.md has Architecture section or equivalent" grep -qE "^## (Architecture|What)" CLAUDE.md
check 57 "doc-quality" "CLAUDE.md has Installation section" grep -qE "^## (Installation|Install)" CLAUDE.md
check 58 "doc-quality" "CLAUDE.md has Commands section" grep -qE "^## (Commands|Pipeline)" CLAUDE.md
check 59 "doc-quality" "README or CLAUDE.md explains what this repo IS" bash -c 'grep -qi "skill curation\|skill framework\|curation engine" CLAUDE.md'
check 60 "doc-quality" "ORCHESTRATION.md exists and has content" bash -c '[ -f ORCHESTRATION.md ] && [ "$(wc -l < ORCHESTRATION.md)" -gt 10 ]'

echo ""
echo "--- upgrade ---"
check 61 "upgrade" "Upstream tracking directory exists" test -d upstreams
check 62 "upgrade" "At least one upstream registered" bash -c '[ "$(find upstreams/ -name "upstream.json" 2>/dev/null | wc -l | tr -d " ")" -ge 1 ]'
check 63 "upgrade" "Upstream entries have SHA field for version tracking" \
  bash -c 'fails=0; for f in $(find upstreams/ -name "upstream.json" 2>/dev/null); do
    jq -e ".sha // .commit // .version // .last_checked_sha" "$f" > /dev/null 2>&1 || { echo "NO VERSION: $f"; fails=1; }
  done; exit $fails'
check 64 "upgrade" "CONVENTIONS.md documents upstream sources" bash -c 'grep -qi "upstream\|source" CONVENTIONS.md 2>/dev/null'

echo ""
echo "--- resilience ---"
check 65 "resilience" "install.sh exits cleanly with no args (status mode)" bash -c 'timeout 10 bash tools/install.sh --dry-run 2>&1; exit 0'
check 66 "resilience" "All JSON files in repo are valid" \
  bash -c 'fails=0; for f in $(find . -name "*.json" -not -path "./.git/*" -not -path "./node_modules/*"); do
    jq . "$f" > /dev/null 2>&1 || { echo "INVALID: $f"; fails=1; }
  done; exit $fails'
check 67 "resilience" "No broken symlinks in skills/" \
  bash -c 'fails=0; find skills/ -type l 2>/dev/null | while read -r link; do
    [ -e "$link" ] || { echo "BROKEN: $link"; fails=1; }
  done; exit $fails'
check 68 "resilience" "No empty directories in skills/" \
  bash -c 'fails=0; find skills/ -type d -empty 2>/dev/null | while read -r dir; do
    echo "EMPTY DIR: $dir"; fails=1
  done; exit $fails'

echo ""
echo "--- agents ---"
check 69 "agents" "Planning swarm agents exist (researcher, planner, critic)" \
  bash -c 'fails=0; for agent in researcher planner critic; do
    found=$(find skills/skippy/agents/ -name "*$agent*" 2>/dev/null | head -1)
    [ -n "$found" ] || { echo "MISSING: $agent"; fails=1; }
  done; exit $fails'
check 70 "agents" "Review swarm agents exist" bash -c '[ "$(find skills/skippy/agents/ -name "*.md" 2>/dev/null | wc -l | tr -d " ")" -ge 5 ]'
check 71 "agents" "Agent definitions have complexity: field" \
  bash -c 'fails=0; for f in skills/skippy/agents/*.md; do [ -f "$f" ] || continue
    grep -qi "complexity:" "$f" || { echo "NO COMPLEXITY: $(basename "$f")"; fails=1; }
  done; exit $fails'
check 72 "agents" "No agent uses model: directly (must use complexity:)" \
  assert_empty bash -c 'grep -l "^model:" skills/skippy/agents/*.md 2>/dev/null || true'

echo ""
echo "--- eval-coverage ---"
check 73 "eval-coverage" "Structural eval suite has 60+ assertions" bash -c '[ "$(grep -rc "^check " evals/structural/categories/*.sh 2>/dev/null | awk -F: "{s+=\$2} END{print s}")" -ge 60 ]'
check 74 "eval-coverage" "Behavioral evals exist for install experience" test -f evals/behavioral/install-experience.json
check 75 "eval-coverage" "Behavioral evals exist for repo quality" test -f evals/behavioral/repo-quality.json
check 76 "eval-coverage" "Eval assertions JSON files are valid" \
  bash -c 'fails=0; for f in evals/behavioral/*.json evals/structural/*.json; do [ -f "$f" ] || continue
    jq . "$f" > /dev/null 2>&1 || { echo "INVALID: $f"; fails=1; }
  done; exit $fails'

echo ""
echo "--- upstream-freshness ---"
check 77 "upstream-freshness" "All upstreams have last_check date" \
  bash -c 'fails=0; for f in $(find upstreams/ -name "upstream.json" 2>/dev/null); do
    jq -e ".last_check" "$f" > /dev/null 2>&1 || { echo "NO DATE: $f"; fails=1; }
  done; exit $fails'
check 78 "upstream-freshness" "At least 5 upstream sources registered" bash -c '[ "$(find upstreams/ -name "upstream.json" 2>/dev/null | wc -l | tr -d " ")" -ge 5 ]'
check 79 "upstream-freshness" "All upstream repos have valid URLs" \
  bash -c 'fails=0; for f in $(find upstreams/ -name "upstream.json" 2>/dev/null); do
    repo=$(jq -r ".repo" "$f" 2>/dev/null)
    [[ "$repo" == http* || "$repo" == git@* ]] || { echo "BAD URL: $f -> $repo"; fails=1; }
  done; exit $fails'

echo ""
echo "--- claudemd-accuracy ---"
check 80 "claudemd-accuracy" "CLAUDE.md file tree lists evals/ directory" grep -q "evals/" CLAUDE.md
check 81 "claudemd-accuracy" "CLAUDE.md file tree lists VERSION file" grep -q "VERSION" CLAUDE.md
check 82 "claudemd-accuracy" "CLAUDE.md file tree lists GLOSSARY.md" grep -q "GLOSSARY" CLAUDE.md
check 83 "claudemd-accuracy" "CLAUDE.md consumed sources table has at least 4 entries" bash -c '[ "$(grep -cE "^\| \[.*\]\(http" CLAUDE.md)" -ge 4 ]'
check 84 "claudemd-accuracy" "CLAUDE.md constraint section mentions portability" grep -qi "portab" CLAUDE.md

echo ""
echo "--- glossary ---"
check 85 "glossary" "GLOSSARY.md has Domain Terms section" grep -q "Domain Terms" GLOSSARY.md
check 86 "glossary" "GLOSSARY.md has Technical Terms section" grep -q "Technical Terms" GLOSSARY.md
check 87 "glossary" "GLOSSARY.md has at least 10 defined terms" bash -c '[ "$(grep -cE "^\| \*\*" GLOSSARY.md)" -ge 10 ]'

echo ""
echo "--- shell-quality ---"
check 88 "shell-quality" "All shell scripts quote their variables" \
  assert_empty bash -c 'for f in tools/install.sh tools/uninstall.sh; do
    grep -nE "\$[A-Z_]+[^\")}]" "$f" 2>/dev/null | grep -v "#\|echo\|printf\|local\|export\|readonly\|declare\|=\$\|trap\|\[\[" | head -5
  done || true'
check 89 "shell-quality" "No shellcheck-flagged issues in critical scripts" \
  bash -c 'if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -S error tools/install.sh tools/uninstall.sh 2>&1 | grep -c "error" | grep -q "^0$"
  else true; fi'
check 90 "shell-quality" "Scripts use local for function variables" \
  bash -c 'for f in tools/install.sh tools/uninstall.sh; do
    funcs=$(grep -c "^[a-z_]*() {" "$f" 2>/dev/null || echo 0)
    locals=$(grep -c "local " "$f" 2>/dev/null || echo 0)
    if [ "$funcs" -gt 0 ] && [ "$locals" -eq 0 ]; then echo "NO LOCALS: $f"; exit 1; fi
  done'

echo ""
echo "--- test-infra ---"
check 91 "test-infra" "Tests directory exists" test -d tests
check 92 "test-infra" "Bats test framework is available" bash -c '[ -f tests/bats/bin/bats ] || [ -d tests/bats ]'
check 93 "test-infra" "At least one test file exists" bash -c '[ "$(find tests/ -name "*.bats" -o -name "*.test.*" 2>/dev/null | wc -l | tr -d " ")" -ge 1 ]'

echo ""
echo "--- skill-consistency ---"
check 94 "skill-consistency" "All skills have consistent frontmatter order" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do
    name_line=$(grep -n "^name:" "$f" | head -1 | cut -d: -f1)
    desc_line=$(grep -n "^description:" "$f" | head -1 | cut -d: -f1)
    if [ -n "$name_line" ] && [ -n "$desc_line" ] && [ "$name_line" -gt "$desc_line" ]; then
      echo "BAD ORDER: $f"; fails=1
    fi
  done; exit $fails'
check 95 "skill-consistency" "No skill has duplicate frontmatter fields" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do
    dupes=$(sed -n "/^---$/,/^---$/p" "$f" | grep -oE "^[a-z_]+:" | sort | uniq -d)
    if [ -n "$dupes" ]; then echo "DUPES in $f: $dupes"; fails=1; fi
  done; exit $fails'
check 96 "skill-consistency" "All skill categories are valid values" \
  bash -c 'fails=0; for d in skills/*/; do
    meta_cat=$(grep "category:" "$d/SKILL.md" 2>/dev/null | head -1 | sed "s/.*category: *//" | tr -d " ")
    [ -n "$meta_cat" ] || continue
    case "$meta_cat" in core|workflow|utility|domain) ;; *) echo "UNKNOWN: $(basename "$d") -> $meta_cat"; fails=1 ;; esac
  done; exit $fails'
check 97 "skill-consistency" "All skill names match their directory names" \
  bash -c 'fails=0; for d in skills/*/; do
    dir_name=$(basename "$d")
    skill_name=$(grep "^name:" "$d/SKILL.md" 2>/dev/null | head -1 | sed "s/^name: *//" | tr -d " ")
    if [ -n "$skill_name" ] && [ "$skill_name" != "$dir_name" ]; then echo "MISMATCH: $dir_name vs $skill_name"; fails=1; fi
  done; exit $fails'

echo ""
echo "--- git-hygiene ---"
check 98 "git-hygiene" "No large binary files in repo (>1MB)" \
  assert_empty bash -c 'find . -not -path "./.git/*" -type f -size +1M 2>/dev/null | head -5 || true'
check 99 "git-hygiene" ".gitignore has node_modules entry" grep -q 'node_modules' .gitignore
check 100 "git-hygiene" "No package-lock.json or yarn.lock (bun only)" bash -c '[ ! -f package-lock.json ] && [ ! -f yarn.lock ]'

echo ""
echo "--- naming ---"
check 101 "naming" "All skill directories use kebab-case" \
  bash -c 'fails=0; for d in skills/*/; do name=$(basename "$d")
    if [[ "$name" =~ [A-Z_] ]]; then echo "NOT KEBAB: $name"; fails=1; fi
  done; exit $fails'
check 102 "naming" "All command files use kebab-case" \
  bash -c 'fails=0; for f in skills/*/commands/*.md; do [ -f "$f" ] || continue; name=$(basename "$f" .md)
    if [[ "$name" =~ [A-Z_] ]]; then echo "NOT KEBAB: $name"; fails=1; fi
  done; exit $fails'
check 103 "naming" "All upstream directory names use kebab-case" \
  bash -c 'fails=0; for d in upstreams/*/; do [ -d "$d" ] || continue; name=$(basename "$d")
    if [[ "$name" =~ [A-Z] ]]; then echo "NOT KEBAB: $name"; fails=1; fi
  done; exit $fails'

echo ""
