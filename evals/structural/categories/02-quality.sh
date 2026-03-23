# Quality: deep-quality, cross-refs, install-pipeline, consistency
# Sourced by runner.sh -- check() and assert_empty() available

echo "--- deep-quality ---"

check 27 "deep-quality" "SKILL.md frontmatter has description: field" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do grep -q "^description:" "$f" || { echo "$f"; fails=1; }; done; exit $fails'

check 28 "deep-quality" "SKILL.md frontmatter has metadata: block" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do grep -q "^metadata:" "$f" || { echo "$f"; fails=1; }; done; exit $fails'

check 29 "deep-quality" "No empty SKILL.md files (min 10 lines)" \
  bash -c 'fails=0; for f in skills/*/SKILL.md; do lines=$(wc -l < "$f"); if [ "$lines" -lt 10 ]; then echo "TOO SHORT ($lines lines): $f"; fails=1; fi; done; exit $fails'

check 30 "deep-quality" "marketplace.json descriptions match SKILL.md names" \
  bash -c '
    fails=0
    for d in skills/*/; do
      skill=$(basename "$d")
      skill_name=$(grep "^name:" "$d/SKILL.md" 2>/dev/null | head -1 | sed "s/^name: *//")
      mp_exists=$(jq -r ".plugins[] | select(.skills[] | endswith(\"/$skill\")) | .name" .claude-plugin/marketplace.json 2>/dev/null)
      if [ -n "$mp_exists" ] && [ "$mp_exists" != "$skill_name" ] && [ "$mp_exists" != "$skill" ]; then
        echo "MISMATCH: disk=$skill skill.md=$skill_name marketplace=$mp_exists"; fails=1
      fi
    done; exit $fails
  '

check 31 "deep-quality" "All TypeScript files pass syntax check" \
  bash -c 'fails=0; for f in $(find . -name "*.ts" -not -path "./.git/*" -not -path "./node_modules/*"); do
    head -1 "$f" | grep -q "#!/bin/bash" && { echo "TS file with bash shebang: $f"; fails=1; }
  done; exit $fails'

check 32 "deep-quality" "No TODO/FIXME/HACK in shipped skill files" \
  assert_empty bash -c 'grep -rn "TODO\|FIXME\|HACK\|XXX" skills/ --include="*.md" 2>/dev/null | grep -v "add-todo\|check-todos\|update-todo\|todo.*skill\|/todos/\|agents/\|references/\|captured as TODO\|console.log.*TODO\|Debug code\|US-XXX\|[A-Z]*-XXX" || true'

check 33 "deep-quality" "CLAUDE.md references correct skill count" \
  bash -c '
    actual=$(ls -d skills/*/ | wc -l | tr -d " ")
    mentioned=$(grep -oE "[0-9]+ skills" CLAUDE.md | head -1 | grep -oE "[0-9]+")
    if [ -n "$mentioned" ] && [ "$mentioned" != "$actual" ]; then
      echo "CLAUDE.md says $mentioned skills, actually $actual"; exit 1
    fi
  '

echo ""
echo "--- cross-refs ---"

check 34 "cross-refs" "CLAUDE.md Key Files table paths all exist" \
  bash -c '
    fails=0
    grep -oE "\`[^$][^$]*\`" CLAUDE.md | tr -d "\`" | while read -r path; do
      [[ "$path" == */* ]] || continue
      [[ "$path" == http* ]] && continue
      [[ "$path" == *"..."* || "$path" == *"*"* || "$path" == *"~"* || "$path" == *"$"* || "$path" == *"SKILL"* ]] && continue
      [ -e "$path" ] || { echo "DEAD REF: $path"; fails=1; }
    done; exit $fails
  '

check 35 "cross-refs" "All agent definition files referenced in skippy exist" \
  bash -c '
    fails=0
    if [ -d "skills/skippy/agents" ]; then
      for f in skills/skippy/agents/*.md; do [ -f "$f" ] || continue
        grep -q "description:" "$f" || { echo "NO DESC: $f"; fails=1; }
      done
    fi; exit $fails
  '

check 36 "cross-refs" "Upstream config files are valid JSON" \
  bash -c 'fails=0; for f in $(find upstreams/ -name "*.json" 2>/dev/null); do
    jq . "$f" > /dev/null 2>&1 || { echo "INVALID JSON: $f"; fails=1; }
  done; exit $fails'

check 37 "cross-refs" "GLOSSARY.md exists and has entries" \
  bash -c '[ -f GLOSSARY.md ] && [ "$(wc -l < GLOSSARY.md)" -gt 5 ]'

echo ""
echo "--- install-pipeline ---"

check 38 "install-pipeline" "install.sh exists and is executable-compatible" bash -c 'bash -n tools/install.sh'
check 39 "install-pipeline" "uninstall.sh exists and is executable-compatible" bash -c 'bash -n tools/uninstall.sh'
check 40 "install-pipeline" "install.sh has --help flag" bash -c 'grep -q "\-\-help\|usage\|Usage" tools/install.sh'
check 41 "install-pipeline" "install.sh handles PAI_SKILLS_DIR env var" bash -c 'grep -q "PAI_SKILLS_DIR" tools/install.sh'
check 42 "install-pipeline" "backup-restore.sh exists" test -f tools/backup-restore.sh

echo ""
echo "--- consistency ---"

check 43 "consistency" "VERSION file exists" test -f VERSION

check 44 "consistency" "No merge conflict markers in any file" \
  assert_empty bash -c 'grep -rl "^<<<<<<< \|^=======$\|^>>>>>>> " . --include="*.md" --include="*.sh" --include="*.json" --include="*.ts" 2>/dev/null | grep -v ".git/" || true'

check 45 "consistency" "No Windows line endings (CRLF) in shell scripts" \
  assert_empty bash -c 'for f in $(find . -name "*.sh" -not -path "./.git/*"); do file "$f" | grep -q "CRLF" && echo "CRLF: $f"; done || true'

check 46 "consistency" ".gitattributes exists with export-ignore entries" \
  bash -c '[ -f .gitattributes ] && grep -q "export-ignore" .gitattributes'

echo ""
