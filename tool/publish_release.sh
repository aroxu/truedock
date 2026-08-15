#!/bin/sh

# Publish a TrueDock release: bump pubspec.yaml, commit, tag, and push.
#
# Usage:
#   tool/publish_release.sh -v 1.0.0
#   tool/publish_release.sh            # interactive prompt for the version
#
# This script only touches pubspec.yaml's version line, commits that change
# (along with anything else already staged/modified in the worktree), creates
# a tag "vX.Y.Z", and pushes both the current branch and the tag. Pushing the
# tag is what triggers .github/workflows/release.yml.
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

pubspec="$project_dir/pubspec.yaml"
if [ ! -f "$pubspec" ]; then
  echo "pubspec.yaml not found at $pubspec" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is not available on PATH." >&2
  exit 127
fi

usage() {
  sed -n '3,10p' "$0"
}

version=''
while [ $# -gt 0 ]; do
  case "$1" in
    -v|--version)
      [ $# -ge 2 ] || { echo "Missing value for $1" >&2; exit 64; }
      version="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 64
      ;;
  esac
done

current_line=$(grep -E '^version:[[:space:]]*' "$pubspec" | head -1)
if [ -z "$current_line" ]; then
  echo "Could not find a 'version:' line in $pubspec" >&2
  exit 1
fi
current_version=$(printf '%s\n' "$current_line" | sed -E 's/^version:[[:space:]]*//')
current_semver=${current_version%%+*}
current_build=${current_version#*+}
if [ "$current_build" = "$current_version" ]; then
  current_build=0
fi

echo "Current pubspec.yaml version: $current_version"

if [ -z "$version" ]; then
  printf 'New version (X.Y.Z) [current: %s]: ' "$current_semver"
  read -r version
  if [ -z "$version" ]; then
    echo "No version entered; aborting." >&2
    exit 1
  fi
fi

case "$version" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *)
    echo "Version must look like X.Y.Z (got: $version)" >&2
    exit 64
    ;;
esac

new_build=$((current_build + 1))
new_version="${version}+${new_build}"
tag="v${version}"

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Tag $tag already exists." >&2
  exit 1
fi

branch=$(git rev-parse --abbrev-ref HEAD)

echo ""
echo "About to release:"
echo "  pubspec.yaml version: $current_version -> $new_version"
echo "  git tag:              $tag"
echo "  branch to push:       $branch"
echo ""
printf 'Press Enter to continue, or Ctrl+C to abort: '
read -r _confirm

sed -E -i.bak "s/^version:[[:space:]]*.*/version: $new_version/" "$pubspec"
rm -f "$pubspec.bak"

git add -A
# ci.yml already excludes tag pushes via tags-ignore, and this same commit
# is what the tag below points at. Do NOT add [skip ci] here: GitHub treats
# that marker at the commit level, so it would also suppress the tag push
# event that release.yml depends on, silently skipping the release build.
git commit -m "🔖 chore(release): $tag"
git tag "$tag"
git push origin "$branch"
git push origin "$tag"

echo ""
echo "Pushed $branch and tag $tag."
echo "GitHub Actions release workflow will build and publish the release."
