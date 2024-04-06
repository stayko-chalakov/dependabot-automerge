#!/bin/bash
#
# if the branch is 'dependabot/*' but the author is not dependabot[bot] then skip the rest of the steps
author=$(git log -1 --pretty=format:'%an')
if [ "$author" != "dependabot[bot]" ]; then
  echo "PR is not from dependabot! Skipping..."
  circleci step halt
fi

# checks for conflicts
mergeable=$(gh pr view --json mergeable | jq -r .mergeable)
echo "Mergeable status is: $mergeable"

if [ "$mergeable" != "MERGEABLE" ]; then
  if [ "$mergeable" == "UNKNOWN" ]; then
    echo "Retrying..."
    sleep 5

    if [ "$mergeable" != "MERGEABLE" ]; then
      echo "PR status is: $mergeable instead of MERGEABLE! Aborting..."
    
      # exit and prevent any later steps from running
      exit 1
    fi
  else
    echo "PR status is: $mergeable instead of MERGEABLE! Aborting..."
    exit 1
  fi
fi

# is the current branch out-of-date with the base branch
merge_state_status=$(gh pr view --json mergeStateStatus | jq -r .mergeStateStatus)
echo "Merge state status is: $merge_state_status"


if [  "$merge_state_status" != "BLOCKED" ]; then
  echo "PR can't be merged at the moment! Merge state status is: $merge_state_status. Aborting..."
  exit 1
fi

patch=$1
minor=$2
major=$3
pr_title=$(gh pr view --json title | jq -r .title)

echo "patch: $patch"
echo "minor: $minor"
echo "major: $major"
echo "pr_title: $pr_title"

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
  patch_keywords=("production-patch" "development-patch")
  if contains_keywords "$pr_title" "${patch_keywords[@]}"; then
    echo "Patch update detected. Proceeding with the job."
    exit 0
  fi
fi

if [ "$minor" == "true" ]; then
  minor_keywords=("production-minor" "development-minor")
  if contains_keywords "$pr_title" "${minor_keywords[@]}"; then
    echo "Minor update detected. Proceeding with the job."
    exit 0
  fi
fi

if [ "$major" == "true" ]; then
  major_keywords=("production-major" "development-major")
  if contains_keywords "$pr_title" "${major_keywords[@]}"; then
    echo "Major update detected. Proceeding with the job."
    exit 0
  fi
fi

if [ "$patch" == "false" ] && [ "$minor" == "false" ] && [ "$major" == "false" ]; then
  echo "Skipping job: None of the conditions met."
  # ending job without failure
  circleci-agent step halt
fi
