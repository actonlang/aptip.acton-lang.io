#!/bin/bash
#
# Drops the oldest "Add Acton tip" commits from origin/main until its files fit in
# max_bytes, and puts the new history in refs/heads/cleaned for the workflow to
# push.
#
# The clone is blobless, so blob sizes come from the GitHub API, and each kept
# commit is replayed from its changes with update-index instead of a rebase,
# which would need file contents.

set -euo pipefail

max_bytes=9000000000
old=$(git rev-parse origin/main)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export GIT_INDEX_FILE=$work/index   # commits are replayed in this index, not the checkout's

# "<blob>\t<size>" for every file on main.
gh api "repos/{owner}/{repo}/git/trees/$old?recursive=1" \
    --jq '.tree[] | select(.type == "blob") | "\(.sha)\t\(.size)"' > "$work/sizes"

# Bytes that dropping commit $1 removes from main: the files it set that main still has.
freed() {
    git diff-tree -r --no-commit-id "$1" |
        awk -F'\t' 'NR == FNR { size[$1] = $2; next } { split($1, f, " "); t += size[f[4]] } END { printf "%.0f\n", t }' \
            "$work/sizes" -
}

size=$(awk -F'\t' '{ t += $2 } END { printf "%.0f\n", t }' "$work/sizes")
git log --reverse --grep='^Add Acton tip' --format=%H "$old" > "$work/adds"
newest=$(tail -n 1 "$work/adds")
: > "$work/drop"
while read -r c; do
    (( size > max_bytes )) || break
    if [[ $c == "$newest" ]]; then
        echo "Cannot fit the newest release within $max_bytes bytes ($size bytes remain)." >&2
        exit 1
    fi
    echo "$c" >> "$work/drop"
    size=$(( size - $(freed "$c") ))
done < "$work/adds"

if [[ ! -s $work/drop ]]; then
    echo "Source repository: $size / $max_bytes bytes; nothing to drop."
    exit 0
fi

# Replay every commit after the oldest dropped one, except the dropped ones: apply
# its changes to the index, then copy the commit with the new tree and parent.
base=$(git rev-parse "$(head -n 1 "$work/drop")^")
git read-tree "$base"
parent=$base
for c in $(git rev-list --reverse "$base..$old"); do
    grep -qxF "$c" "$work/drop" && continue
    git diff-tree -r --no-commit-id "$c" |
        awk -F'\t' '{ split($1, f, " "); print f[2] " " f[4] "\t" $2 }' |
        git update-index --index-info
    tree=$(git write-tree --missing-ok)
    parent=$(git cat-file commit "$c" |
        sed "1,/^\$/{ s/^tree .*/tree $tree/; s/^parent .*/parent $parent/; }" |
        git hash-object -t commit -w --stdin)
done
git update-ref refs/heads/cleaned "$parent"

echo "Dropped $(grep -c . "$work/drop") of $(grep -c . "$work/adds") Add commits, up to: $(git log -1 --format=%s "$(tail -n 1 "$work/drop")")"
echo "cleaned: $parent (origin/main: $old)"
echo "Source repository: $size / $max_bytes bytes."
