# Foundations: skill-structure, marketplace, tooling, docs, security, portability
# Sourced by runner.sh -- check() and assert_empty() available

echo "--- skill-structure ---"

check 1 "skill-structure" "Every skills/ dir has SKILL.md" \
  bash -c 'fails=0; for d in skills/*/; do [ -f "$d/SKILL.md" ] || { echo "$d"; fails=1; }; done; exit $fails'

check 2 "skill-structure" "Every SKILL.md has name: in frontmatter" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do grep -q "^name:" "$f" || { echo "$f"; fails=1; }; done; exit $fails'

check 3 "skill-structure" "No SKILL.md file exceeds 750 lines" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do lines=$(wc -l < "$f"); if [ "$lines" -gt 750 ]; then echo "OVER ($lines): $f"; fails=1; fi; done; exit $fails'

check 4 "skill-structure" "No #!/bin/bash shebangs anywhere" \
  bash -c 'fails=0; for f in $(find . -name "*.sh" -not -path "./.git/*"); do head -1 "$f" | grep -q "#!/bin/bash" && { echo "BAD SHEBANG: $f"; fails=1; }; done; exit $fails'

check 5 "skill-structure" "Commands dirs have .md files" \
  bash -c 'fails=0; for d in skills/*/commands/; do [ -d "$d" ] || continue; ls "$d"*.md >/dev/null 2>&1 || { echo "EMPTY: $d"; fails=1; }; done; exit $fails'

check 6 "skill-structure" "SKILL.md has structural sections (## headers or xml tags)" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do grep -qE "^## |^<[a-z_]+>" "$f" || { echo "$f"; fails=1; }; done; exit $fails'

echo ""
echo "--- marketplace ---"

check 7 "marketplace" "marketplace.json is valid JSON" \
  bash -c 'jq . .claude-plugin/marketplace.json > /dev/null'

check 8 "marketplace" "Marketplace has at least 20 skill entries" \
  bash -c '
    count=$(jq -r ".plugins[].skills[]" .claude-plugin/marketplace.json | wc -l | tr -d " ")
    [ "$count" -ge 20 ] || { echo "Only $count entries"; exit 1; }
  '

check 9 "marketplace" "All marketplace paths exist on disk" \
  bash -c '
    fails=0
    for p in $(jq -r ".plugins[].skills[]" .claude-plugin/marketplace.json); do
      [ -d "$p" ] || { echo "MISSING: $p"; fails=1; }
    done; exit $fails
  '

check 10 "marketplace" "No duplicate plugin names" \
  bash -c '
    dupes=$(jq -r ".plugins[].name" .claude-plugin/marketplace.json | sort | uniq -d)
    [ -z "$dupes" ] || { echo "DUPES: $dupes"; exit 1; }
  '

echo ""
echo "--- tooling ---"

check 11 "tooling" "All .sh files pass bash -n syntax check" \
  bash -c 'fails=0; for f in $(find . -name "*.sh" -not -path "./.git/*"); do bash -n "$f" 2>/dev/null || { echo "SYNTAX: $f"; fails=1; }; done; exit $fails'

check 12 "tooling" "Tool scripts use set -e or set -euo pipefail" \
  bash -c 'fails=0; for f in tools/*.sh; do [ -f "$f" ] || continue; grep -qE "set -e|set -euo" "$f" || { echo "MISSING: $f"; fails=1; }; done; exit $fails'

check 13 "tooling" "common.sh sources correctly from repo root" \
  bash -c 'source tools/lib/common.sh && type skippy_pass >/dev/null 2>&1'

check 14 "tooling" "No interactive read without terminal check" \
  bash -c '
    problem_files=$(grep -rn "read -r -p\|read -p" tools/*.sh 2>/dev/null | grep -v "#.*read" || true)
    if [ -n "$problem_files" ]; then
      fails=0
      echo "$problem_files" | while IFS=: read -r file line rest; do
        grep -q "\-t 0\|interactive\|is_tty" "$file" || { echo "UNGUARDED READ: $file:$line"; fails=1; }
      done; exit $fails
    fi
  '

echo ""
echo "--- docs ---"

check 15 "docs" "INDEX.md exists" test -f INDEX.md
check 16 "docs" "CLAUDE.md exists" test -f CLAUDE.md
check 17 "docs" "CONVENTIONS.md exists" test -f CONVENTIONS.md

check 18 "docs" "Key planning files exist" \
  bash -c 'fails=0; for f in .planning/PROJECT.md .planning/ROADMAP.md .planning/STATE.md; do [ -f "$f" ] || { echo "MISSING: $f"; fails=1; }; done; exit $fails'

check 19 "docs" "INDEX.md skill count matches skills/ directory count" \
  bash -c '
    disk_count=$(ls -d skills/*/ 2>/dev/null | wc -l | tr -d " ")
    index_mentioned=$(grep -oE "[0-9]+ skills" INDEX.md | head -1 | grep -oE "[0-9]+")
    [ -n "$index_mentioned" ] && [ "$index_mentioned" -eq "$disk_count" ] || { echo "disk=$disk_count index=$index_mentioned"; exit 1; }
  '

echo ""
echo "--- security ---"

check 20 "security" "No .env files tracked in git" assert_empty git ls-files '*.env'
check 21 "security" ".gitignore covers .env" grep -q '\.env' .gitignore
check 22 "security" ".gitignore covers .DS_Store" grep -q 'DS_Store' .gitignore

check 23 "security" "No hardcoded tokens/passwords in skill files" \
  assert_empty bash -c 'grep -rin "api_key\s*=\|password\s*=\|token\s*=" skills/ --include="*.md" --include="*.sh" | grep -v "example\|placeholder\|YOUR_\|<.*>\|documentation\|N8N_API_KEY\|get_secret\|get_credential\|vaultwarden\|gh api\|registration.token\|\$(.*)\|your.key\|your_key\|your-key\|secret123\|environ\|\.env\|\.get(\|references/\|README\|LITELLM_API_KEY\|GEMINI_API_KEY\|REPLICATE_API_KEY\|OPENAI_API_KEY\|patterns\.\|\.split(\|Workflows/\|access_token\|header.*payload.*signature\|const token\|JSON\.parse" || true'

echo ""
echo "--- portability ---"

check 24 "portability" "No hardcoded /Users/rico in skill files" \
  assert_empty grep -r '/Users/rico' skills/ --include='*.md' --include='*.sh'

check 25 "portability" "No hardcoded /home/rico in skill files" \
  assert_empty grep -r '/home/rico' skills/ --include='*.md' --include='*.sh'

check 26 "portability" "Skills use relative paths or env vars, not absolute" \
  assert_empty bash -c 'grep -rn "^[^#]*\"/Users/\|^[^#]*\"/home/" skills/ --include="*.md" --include="*.sh" 2>/dev/null | grep -v "example\|template\|placeholder\|/home/runner\|/home/n8n\|/home/litellm\|generic" || true'

echo ""
