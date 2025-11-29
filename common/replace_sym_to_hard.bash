#!/usr/bin/env bash
set -euo pipefail

TARGET_DIRS=("$@")

if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
    echo "Usage: $0 <directory1> [directory2 ...]"
    exit 1
fi

for DIR in "${TARGET_DIRS[@]}"; do
    [ -d "$DIR" ] || {
        echo "❗ Directory not found: $DIR"
        continue
    }

    find "$DIR" -type l -print0 | while IFS= read -r -d '' symlink; do
        link_dir="$(dirname -- "$symlink")"
        target_rel="$(readlink -- "$symlink")"
        target_abs="$(realpath -m -- "$link_dir/$target_rel")"

        [[ -f $target_abs ]] || continue

        rel_path="$(realpath --relative-to="$link_dir" -- "$target_abs")"

        (
            cd "$link_dir" || exit
            rm -- "$(basename -- "$symlink")" || {
                echo "❌ rm failed: $symlink"
                exit 1
            }
            ln -- "$rel_path" "$(basename -- "$symlink")" || {
                echo "❌ ln failed: $symlink → $rel_path"
            }
        )
    done
done
