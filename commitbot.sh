#!/usr/bin/env bash
# Run a command, then commit and push whatever it changed.
# Usage: commitbot.sh "<command>" ["<commit message>"]
set -euo pipefail

command=${1:?usage: commitbot.sh "<command>" ["<commit message>"]}
message=${2:-"chore: automated update"}

cd "$(git rev-parse --show-toplevel)"

# Committing on top of a dirty tree would sweep unrelated work into the bot's commit.
if [ -n "$(git status --porcelain)" ]; then
  echo "commitbot: working tree is not clean, refusing to run" >&2
  exit 1
fi

bash -euo pipefail -c "$command"

git add -A
if git diff --cached --quiet; then
  echo "commitbot: nothing changed"
  exit 0
fi

git commit -m "$message"
git push origin HEAD
