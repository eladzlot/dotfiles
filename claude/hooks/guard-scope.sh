#!/usr/bin/env bash
# PreToolUse guard.
#
# Claude Code runs in bypassPermissions mode (see ../settings.json), so nothing
# prompts by default. This hook puts the prompts back for the two things that
# should stay under manual control:
#
#   1. Writes that land outside the project folder (and outside /tmp).
#   2. git commit / git push, including the `git -C DIR ...` forms that a plain
#      `Bash(git commit:*)` permission rule does not match.
#
# Returning permissionDecision:"ask" forces a real permission prompt even under
# bypassPermissions (verified against Claude Code 2.1.238).
#
# Reads the PreToolUse payload on stdin; prints nothing (= no opinion) unless a
# prompt is warranted.

set -uo pipefail

input=$(cat)

# --- tiny JSON field readers (no jq on this box) -----------------------------
# Good enough for the flat, well-formed payload Claude Code emits.

json_str() { # json_str <key>  -> value of the first "key":"..." pair
  printf '%s' "$input" |
    grep -oP "\"$1\"\\s*:\\s*\"(\\\\.|[^\"\\\\])*\"" |
    head -1 |
    sed -e "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//" -e 's/"$//' \
        -e 's/\\n/\n/g' -e 's/\\t/\t/g' -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}

ask() { # ask <reason>   reason must not contain " or \
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

tool=$(json_str tool_name)
cwd=$(json_str cwd)
[[ -n "$cwd" ]] || cwd=$PWD

# --- what counts as "inside" -------------------------------------------------

ROOTS=()
for r in "${CLAUDE_PROJECT_DIR:-}" "$cwd" /tmp /var/tmp "${TMPDIR:-}"; do
  [[ -n "$r" ]] && ROOTS+=("$(realpath -m -- "$r" 2>/dev/null || printf '%s' "$r")")
done

in_scope() {
  local p
  p=$(cd -- "$cwd" 2>/dev/null && realpath -m -- "$1" 2>/dev/null) || return 1
  local root
  for root in "${ROOTS[@]}"; do
    [[ "$p" == "$root" || "$p" == "$root"/* ]] && return 0
  done
  return 1
}

# --- file-editing tools: exact path, exact answer ----------------------------

case "$tool" in
  Write | Edit | NotebookEdit)
    path=$(json_str file_path)
    [[ -n "$path" ]] || path=$(json_str notebook_path)
    [[ -n "$path" ]] || exit 0
    in_scope "$path" || ask "Writes outside the project folder and /tmp need your approval"
    exit 0
    ;;
  Bash) ;;
  *) exit 0 ;;
esac

# --- Bash ---------------------------------------------------------------------

cmd=$(json_str command)
[[ -n "$cmd" ]] || exit 0

# git commit / git push in any spelling (git -C DIR commit, git --git-dir=... push)
if grep -qE '(^|[;&|(]|&&|\|\|)[[:space:]]*(sudo[[:space:]]+)?git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+(commit|push)([[:space:]]|$)' <<<"$cmd"; then
  ask "Commits and pushes stay under manual control"
fi

if grep -qE '(^|[;&|(]|&&|\|\|)[[:space:]]*sudo([[:space:]]|$)' <<<"$cmd"; then
  ask "sudo runs outside the project sandbox"
fi

# Only inspect paths when the command actually writes something, so read-only
# pokes around the filesystem (cat /etc/os-release, ls /usr/share, ...) stay free.
MUTATORS='rm|rmdir|mv|cp|mkdir|touch|tee|chmod|chown|chgrp|ln|truncate|shred|unlink|dd|install|rsync|patch'

candidates=()

# redirection targets:  > file   >> file   (but not 2>&1, not >&2)
while read -r t; do
  [[ -n "$t" ]] && candidates+=("$t")
done < <(grep -oP '(?<![0-9>&])>>?[[:space:]]*(?![&(])[^[:space:];&|)"'"'"']+' <<<"$cmd" |
  sed -E 's/^>+[[:space:]]*//')

# arguments of mutating commands, plus `sed -i` / `perl -i` in-place edits
if grep -qE "(^|[;&|(]|&&|\\|\\|)[[:space:]]*($MUTATORS)([[:space:]]|$)" <<<"$cmd" ||
  grep -qE '(^|[[:space:]])(sed|perl)[[:space:]]+(-[^[:space:]]*[[:space:]]+)*-i' <<<"$cmd"; then
  while read -r t; do
    [[ -n "$t" ]] && candidates+=("$t")
  done < <(grep -oP '(?<![\w=/.-])(~|/)[^[:space:];&|)"'"'"']*' <<<"$cmd")
fi

for t in "${candidates[@]:-}"; do
  [[ -n "$t" ]] || continue
  t=${t/#\~/$HOME}
  # a bare /dev/null and friends are noise, not filesystem changes
  case "$t" in /dev/null | /dev/stdout | /dev/stderr | /dev/tty) continue ;; esac
  in_scope "$t" || ask "That writes outside the project folder and /tmp"
done

exit 0
