#!/bin/sh
# Credential-blocking pre-commit hook for this repository (see README).
# Install from the repository root after a fresh checkout:
#   cp scripts/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
# Refuse to commit anything that looks like a credential.
fail=0
for f in "$@"; do
  [ -f "$f" ] || continue
  if grep -nEi '(sk-[A-Za-z0-9_-]{16,}|(api[_-]?key|secret|password|token)["'"'"']?[[:space:]]*[:=][[:space:]]*"[^"]{12,})' "$f"; then
    echo "pre-commit: possible secret in $f (shown above)" >&2
    fail=1
  fi
done
[ "$fail" -eq 0 ] || { echo "Commit blocked. Move the value to an {env:NAME} reference or drop the file." >&2; exit 1; }
exit 0
