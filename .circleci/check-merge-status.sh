# if the branch is 'dependabot/*' but the author is not dependabot[bot] then skip the rest of the steps
# author=$(git log -1 --pretty=format:'%an')
# if [ "$author" != "dependabot[bot]" ]; then
  # echo "PR is not from dependabot! Skipping..."
  # circleci step halt
# fi

# checks for conflicts
mergeable=$(gh pr view --json mergeable | jq -r .mergeable)
echo "mergeable: $mergeable"

if [ "$mergeable" != "MERGEABLE" ]; then
  echo "PR has conflicts! Aborting job."
  # exit and prevent any later steps from running
  exit 1
fi

# is the current branch out-of-date with the base branch
merge_state_status=$(gh pr view --json mergeStateStatus | jq -r .mergeStateStatus)
echo "mergeStateStatus: $merge_state_status"


if [  "$merge_state_status" != "BLOCKED" ]; then
  echo "PR is out of date with the base branch! Rebasing..."
  gh pr comment $CIRCLE_PULL_REQUEST --body "@dependabot rebase"
  # exit and prevent any later steps from running
  exit 0
fi

patch = $1
minor = $2
major = $3

pr_title = $(gh pr view --json title | jq -r .title)

# Function to check if PR title contains specified keywords
contains_keywords() {
  local title="$1"
  shift
  local keywords=("$@")

  for keyword in "${keywords[@]}"; do
    if [[ "$title" == *"$keyword"* ]]; then
      return 0
    fi
  done

  return 1
}

# Check conditions for skipping the job based on parameters and PR title
if [ "$patch" == "true" ]; then
  patch_keywords=("production-patch-version-updates" "development-patch-version-updates" "production-patch-security-updates" "development-patch-security-updates")
  if ! contains_keywords "$pr_title" "${patch_keywords[@]}"; then
    echo "Skipping job: Patch is true but PR doesn't update patch versions."
    exit 0
  fi
fi

if [ "$minor" == "true" ]; then
  minor_keywords=("production-minor-version-updates" "development-minor-version-updates" "production-minor-security-updates" "development-minor-security-updates")
  if ! contains_keywords "$pr_title" "${minor_keywords[@]}"; then
    echo "Skipping job: Minor is true but PR doesn't update minor versions."
    exit 0
  fi
fi

if [ "$major" == "true" ]; then
  major_keywords=("production-major-version-updates" "development-major-version-updates" "production-major-security-updates" "development-major-security-updates")
  if ! contains_keywords "$pr_title" "${major_keywords[@]}"; then
    echo "Skipping job: Major is true but PR doesn't update major versions."
    exit 0
  fi
fi

echo "All conditions met. Proceeding with the job."
