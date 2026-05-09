#!/usr/bin/env bash
# Setup PAI bin symlinks
# Symlinks all executable tools to ~/.config/pai/bin/

set -e

PAI_ROOT="$HOME/.config/pai"
BIN_DIR="$PAI_ROOT/bin"

echo "Setting up PAI bin symlinks..."

# Symlink from Tools/ directory
for tool in "$PAI_ROOT/Tools"/*.ts "$PAI_ROOT/Tools"/*.sh; do
  [ -f "$tool" ] || continue
  [ -x "$tool" ] || continue

  basename=$(basename "$tool")
  name="${basename%.*}"  # Remove extension

  ln -sf "$tool" "$BIN_DIR/$name"
  echo "  ✓ $name"
done

# Symlink from commands/.local/ directory
for cmd in "$PAI_ROOT/commands/.local"/*.ts; do
  [ -f "$cmd" ] || continue
  [ -x "$cmd" ] || continue

  basename=$(basename "$cmd")
  name="${basename%.*}"  # Remove extension

  ln -sf "$cmd" "$BIN_DIR/$name"
  echo "  ✓ $name"
done

echo ""
echo "✅ PAI bin symlinks created in $BIN_DIR"
echo ""
echo "Add to ~/.zshrc:"
echo '  export PATH="$HOME/.config/pai/bin:$HOME/.config/pai-private/bin:$PATH"'
