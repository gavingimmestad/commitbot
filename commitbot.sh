#!/usr/bin/env bash
# Run a command, then commit and push whatever it changed.
# Usage: commitbot.sh "<command>" ["<commit message>"]
set -euo pipefail

command=${1:?usage: commitbot.sh "<command>" ["<commit message>"]}
message=${2:-"chore: automated update"}

die() { echo "commitbot: $1" >&2; exit 1; }

cd "$(git rev-parse --show-toplevel)"

# Check everything that would block the commit or push before the command changes any files.
branch=$(git symbolic-ref -q --short HEAD) || die "not on a branch (detached HEAD)"
git var GIT_AUTHOR_IDENT >/dev/null && git var GIT_COMMITTER_IDENT >/dev/null ||
  die "git user.name and user.email are not set"
dirty=$(git status --porcelain)
[ -z "$dirty" ] || die "working tree is not clean, refusing to run:
$dirty"
# Pushing would publish these too. A branch that was never pushed has nothing to compare with.
if git rev-parse -q --verify "refs/remotes/origin/$branch" >/dev/null; then
  [ -z "$(git rev-list "refs/remotes/origin/$branch..HEAD")" ] ||
    die "$branch has unpushed commits, push them first"
fi

bash -euo pipefail -c "$command"

git add -A
if git diff --cached --quiet; then
  echo "commitbot: nothing changed"
  exit 0
fi

git commit -m "$message"
if ! git push origin HEAD; then
  echo "commitbot: push failed, rebasing on origin/$branch and retrying once" >&2
  if ! git pull --rebase origin "$branch"; then
    git rebase --abort 2>/dev/null || true
    die "could not rebase on origin/$branch, the commit was kept locally"
  fi
  git push origin HEAD || die "push failed, the commit was kept locally"
fi
