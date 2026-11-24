#!/usr/bin/env bash
set -euo pipefail
bot="$(cd "$(dirname "$0")" && pwd)/commitbot.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# Ignore the machine's own git config so results do not depend on it.
touch "$tmp/gitconfig"
export GIT_CONFIG_GLOBAL="$tmp/gitconfig"
unset EMAIL
git config --global init.defaultBranch main
git config --global user.name t
git config --global user.email t@example.com

git init -q --bare "$tmp/remote.git"
fresh() { cd "$tmp"; rm -rf work; git clone -q "$@" "file://$tmp/remote.git" work 2>/dev/null; cd work; }
pushed() { git -C "$tmp/remote.git" rev-list --count main; }
fail() { echo "FAIL: $1" >&2; exit 1; }
refuses() { # <expected error> <description>
  if out=$(bash "$bot" "echo ran > ran.txt" 2>&1); then fail "$2"; fi
  case $out in *"$1"*) ;; *) fail "$2: wrong error: $out" ;; esac
  [ ! -e ran.txt ] || fail "$2: the command still ran"
}

fresh
git commit -q --allow-empty -m init
git push -q origin HEAD

bash "$bot" "echo one > data.txt" 'msg with "quotes" and $(id)'
[ "$(pushed)" = 2 ] || fail "a change is committed and pushed"
[ "$(git log -1 --format=%s)" = 'msg with "quotes" and $(id)' ] || fail "message is kept literally"

bash "$bot" "echo one > data.txt"
[ "$(pushed)" = 2 ] || fail "no change means no commit"

if bash "$bot" "echo two > data.txt; false; true"; then fail "a failing command fails the run"; fi
[ "$(pushed)" = 2 ] || fail "a failing command commits nothing"
refuses "data.txt" "a dirty tree is refused and the files are named"

fresh
git checkout -q --detach
refuses "detached HEAD" "a detached HEAD is refused"

fresh
git commit -q --allow-empty -m mine
refuses "unpushed commits" "unpushed commits are refused"

fresh
git config --global --unset user.email
git config --global user.useConfigOnly true
refuses "user.email" "a missing identity is refused"
git config --global user.email t@example.com
[ "$(pushed)" = 2 ] || fail "refused runs push nothing"

# Someone else pushes while the command runs, in a full and a shallow clone.
other() { echo "git clone -q 'file://$tmp/remote.git' '$tmp/o$1' && cd '$tmp/o$1' && echo x > $2 && git add . && git commit -q -m other && git push -q origin HEAD"; }
fresh
bash "$bot" "echo a > a.txt; ( $(other 1 other1.txt) )"
[ "$(pushed)" = 4 ] || fail "a moved branch is rebased and pushed"
fresh --depth 1
bash "$bot" "echo b > b.txt; ( $(other 2 other2.txt) )"
[ "$(pushed)" = 6 ] || fail "a moved branch is rebased and pushed from a shallow clone"

fresh
if bash "$bot" "echo c > clash.txt; ( $(other 3 clash.txt) )"; then fail "a conflict fails the run"; fi
[ "$(pushed)" = 7 ] || fail "a conflict does not overwrite the other commit"
[ -z "$(git status --porcelain)" ] && git symbolic-ref -q HEAD >/dev/null || fail "a conflict leaves no half-done rebase"
refuses "unpushed commits" "a stranded commit is reported, not silently skipped"

echo "all tests passed"
