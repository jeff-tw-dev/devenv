#!/bin/bash
set -euo pipefail

# Script to clone supabase/agent-skills via ghq and symlink supabase-postgres-best-practices
# to ~/.gemini/skills and ~/.claude/skills

REPO_URL="https://github.com/supabase/agent-skills.git"
SKILLS=("supabase-postgres-best-practices")
GEMINI_SKILLS_DIR="$HOME/.gemini/skills"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

echo "Cloning repo with ghq..."
ghq get "$REPO_URL"

REPO_PATH=$(ghq list --full-path | grep "/supabase/agent-skills$" | head -1)
if [[ -z "$REPO_PATH" ]]; then
  echo "❌ Failed to find cloned repo path"
  exit 1
fi

echo "Repo at: $REPO_PATH"

mkdir -p "$GEMINI_SKILLS_DIR" "$CLAUDE_SKILLS_DIR"

for skill in "${SKILLS[@]}"; do
  SRC_PATH="$REPO_PATH/skills/$skill"
  if [[ ! -d "$SRC_PATH" ]]; then
    echo "⚠️  Skill '$skill' not found at $SRC_PATH"
    continue
  fi

  ln -sfn "$SRC_PATH" "$GEMINI_SKILLS_DIR/$skill"
  ln -sfn "$SRC_PATH" "$CLAUDE_SKILLS_DIR/$skill"
  echo "✅ Linked $skill → both skills dirs"
done

echo "🎉 Setup complete!"
ls -la "$GEMINI_SKILLS_DIR" | grep -E "$(IFS='|'; echo "${SKILLS[*]}")"
