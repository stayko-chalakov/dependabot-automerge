# checks for conflicts
mergeable=$(gh pr view --json mergeable | jq -r .mergeable)
echo "mergeable: $mergeable"

# is the current branch out-of-date with the base branch
merge_state_status=$(gh pr view --json mergeStateStatus | jq -r .mergeStateStatus)
echo "mergeStateStatus: $merge_state_status"

if [ "$mergeable" != "MERGEABLE" ] || [ "$merge_state_status" != "BLOCKED" ]; then
  echo "PR has conflicts or is out of date with the base branch! Aborting job."
  if [ "$merge_state_status" = "BEHIND" ]; then
    echo "Rebasing the PR branch with the base branch..."
    git rebase main
    git push -f
  fi
  # exit and prevent any later steps from running
  exit 1
fi
