#!/bin/bash

# Set the number of commits to keep
X=${1:-20}  # Default to keeping the last 5 commits if not specified

# Get all commits with the "Add Acton tip" message, in chronological order
all_commits=$(git log --grep="^Add Acton tip" --pretty=format:"%H")

# Count the total number of matching commits
total_commits=$(echo "$all_commits" | wc -l)

# Calculate the number of commits to remove
commits_to_remove_count=$((total_commits - X))

# If there's nothing to remove, exit early
if [ "$commits_to_remove_count" -le 0 ]; then
    echo "No commits to remove."
    exit 0
fi

# Get the commits to remove (the oldest ones)
commits_to_remove=$(echo "$all_commits" | tail -n "$commits_to_remove_count")

# Perform a non-interactive rebase to remove the commits
for commit in $commits_to_remove; do
    git rebase --onto "$commit^" "$commit"
done

# Force push the changes (if required)
# Uncomment the next line if you want to force push the changes after filtering
# git push origin main --force
