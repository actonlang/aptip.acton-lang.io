#!/bin/bash

set -euo pipefail

max_bytes=9000000000

repository_size() {
    git ls-tree -r -l HEAD | awk '{total += $4} END {printf "%.0f\n", total}'
}

size=$(repository_size)
while (( size > max_bytes )); do
    # Rebasing changes descendant hashes, so read the history again each time.
    commits=($(git log --grep="^Add Acton tip" --pretty=format:"%H"))
    if (( ${#commits[@]} <= 1 )); then
        echo "Cannot fit the newest release within $max_bytes bytes ($size bytes remain)." >&2
        exit 1
    fi

    oldest=${commits[${#commits[@]} - 1]}
    git rebase --onto "$oldest^" "$oldest"
    size=$(repository_size)
done

echo "Source repository: $size / $max_bytes bytes."
