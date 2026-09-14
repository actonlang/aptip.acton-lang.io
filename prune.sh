#!/bin/bash

set -euo pipefail

max_bytes=9000000000

repository_size() {
    find acton.gpg CNAME conf db dists pool README.md -type f -printf '%s\n' |
        awk '{total += $1} END {printf "%.0f\n", total}'
}

size=$(repository_size)
versions=($(reprepro --list-format '${version}\n' list tip | sort -Vu))
for version in "${versions[@]}"; do
    if (( size <= max_bytes )); then
        break
    fi
    if [[ "$version" == "${versions[${#versions[@]} - 1]}" ]]; then
        echo "Cannot fit the newest release within $max_bytes bytes ($size bytes remain)." >&2
        exit 1
    fi

    echo "Removing Acton $version to fit the publication budget."
    reprepro remove tip "acton=$version"
    size=$(repository_size)
done

if (( size > max_bytes )); then
    echo "Repository metadata exceeds the $max_bytes byte budget ($size bytes)." >&2
    exit 1
fi
echo "Published repository: $size / $max_bytes bytes."
