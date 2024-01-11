#!/bin/bash

# Initialize arrays to store package names and version numbers
declare -a oldVersions
declare -a newVersions

# Extract version numbers and add them to the array
while read -r line; do
  packageName=$(echo "$line" | grep -Eo '^\-[[:space:]]*"[^"]+":' | sed 's/[[:space:]]*"\([^"]\+\)":/\1/' | tr -d '[:space:]')
  version=$(echo "$line" | grep -Eo '[0-9]+' | head -n 1)
  if [ -n "$version" ]; then
    oldVersions+=("${packageName:1}$version")
    echo "Removed: $(echo $line | sed 's/-[[:space:]]*//g')"
  fi
done <<< "$(git diff HEAD^ HEAD -- package.json | grep -E '^\-[[:space:]]*"[^"]+":\s*"\^([1-9][0-9]*)\.[0-9]+\.[0-9]+"')"

# Extract version numbers and add them to the array
while read -r line; do
  packageName=$(echo "$line" | grep -Eo '^\+[[:space:]]*"[^"]+":' | sed 's/[[:space:]]*"\([^"]\+\)":/\1/' | tr -d '[:space:]')
  version=$(echo "$line" | grep -Eo '[0-9]+' | head -n 1)
  if [ -n "$version" ]; then
    newVersions+=("${packageName:1}$version")
    echo "Added: $(echo $line | sed 's/+[[:space:]]*//g')"
  fi
done <<< "$(git diff HEAD^ HEAD -- package.json | grep -E '^\+[[:space:]]*"[^"]+":\s*"\^([1-9][0-9]*)\.[0-9]+\.[0-9]+"')"

# Compare elements between newVersions and oldVersions
for i in "${!newVersions[@]}"; do
  if [ "${newVersions[$i]}" != "${oldVersions[$i]}" ]; then
    echo "Error: new major bump detected ${newVersions[$i]}"
    exit 1
  fi
done

echo "No major bump found. Exiting successfully."
