#!/usr/bin/env bash
set -euo pipefail

# Remove a file from git history using git-filter-repo if available, otherwise print instructions.
# WARNING: rewriting git history is destructive for shared repos. Read and understand before running.

TARGET_PATH="runner-manager/app-private-key.pem"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not in a git repository. Run this from the repository root." >&2
  exit 1
fi

if command -v git-filter-repo >/dev/null 2>&1; then
  echo "Using git-filter-repo to remove $TARGET_PATH from history..."
  git filter-repo --invert-paths --path "$TARGET_PATH"
  echo "Done. You must force-push the cleaned branches to remote and ask collaborators to reclone." 
  echo "Example: git push --force --all && git push --force --tags"
  exit 0
fi

if command -v bfg >/dev/null 2>&1; then
  echo "Using BFG to remove $TARGET_PATH from history..."
  # BFG rewrites history; create a mirror clone first as recommended
  echo "Recommended flow: create a fresh mirror clone and run BFG there. See BFG docs."
  echo "Example steps:"
  echo "  git clone --mirror <repo> repo.git"
  echo "  cd repo.git"
  echo "  bfg --delete-files $TARGET_PATH"
  echo "  git reflog expire --expire=now --all && git gc --prune=now --aggressive"
  echo "  git push"
  exit 0
fi

cat <<'EOF'
No suitable history-rewriting tool found (git-filter-repo or BFG).
You can either install `git-filter-repo` (preferred) or BFG, or manually remove and rotate the secret.

Manual alternative (less effective):
  1. Remove the file from HEAD: `git rm --cached runner-manager/app-private-key.pem` and commit.
  2. Rotate the compromised key (generate a new key in GitHub App settings).
  3. Use a history-rewriting tool later to purge the secret from history.

Always rotate any secret that was committed before or during this cleanup.
EOF
