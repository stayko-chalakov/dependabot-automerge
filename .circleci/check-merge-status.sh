# if the branch is 'dependabot/*' but the author is not dependabot[bot] then skip the rest of the steps
# author=$(git log -1 --pretty=format:'%an')
# if [ "$author" != "dependabot[bot]" ]; then
  # echo "PR is not from dependabot! Skipping..."
  # circleci step halt
# fi

# checks for conflicts
mergeable=$(gh pr view --json mergeable | jq -r .mergeable)
echo "mergeable: $mergeable"

# is the current branch out-of-date with the base branch
merge_state_status=$(gh pr view --json mergeStateStatus | jq -r .mergeStateStatus)
echo "mergeStateStatus: $merge_state_status"

if [ "$mergeable" != "MERGEABLE" ] || [ "$merge_state_status" != "BLOCKED" ]; then
  echo "PR has conflicts or is out of date with the base branch! Aborting job."
  # exit and prevent any later steps from running
  exit 1
fi
