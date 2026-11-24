#!/usr/bin/env bash
set -euo pipefail
bot="$(cd "$(dirname "$0")" && pwd)/commitbot.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

git init -q --bare "$tmp/remote.git"
git init -q "$tmp/work"
cd "$tmp/work"
git remote add origin "$tmp/remote.git"
git commit -q --allow-empty -m init
git push -q origin HEAD
branch=$(git branch --show-current)
pushed() { git -C "$tmp/remote.git" rev-list --count "$branch"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

bash "$bot" "echo one > data.txt" 'msg with "quotes" and $(id)'
[ "$(pushed)" = 2 ] || fail "a change is committed and pushed"
[ "$(git log -1 --format=%s)" = 'msg with "quotes" and $(id)' ] || fail "message is kept literally"

bash "$bot" "echo one > data.txt"
[ "$(pushed)" = 2 ] || fail "no change means no commit"

if bash "$bot" "echo two > data.txt; false; true"; then fail "a failing command fails the run"; fi
[ "$(pushed)" = 2 ] || fail "a failing command commits nothing"

if bash "$bot" "true"; then fail "a dirty tree is refused"; fi
[ "$(pushed)" = 2 ] || fail "a dirty tree commits nothing"

echo "all tests passed"
