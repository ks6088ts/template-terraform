#!/bin/sh

set -eu

for tool in tfupdate curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '%s is not installed. See docs/tips/terraform-workflow.md.\n' "$tool" >&2
    exit 1
  fi
done

if [ "$#" -eq 0 ]; then
  printf 'No tracked Terraform lock files were found.\n' >&2
  exit 1
fi

work_dir=$(mktemp -d)
trap 'find "$work_dir" -depth -delete' 0
trap 'exit 1' 1 2 3 15

awk '
  /^provider "/ {
    source = $2
    gsub(/"/, "", source)
  }
  /^  version[[:space:]]*=/ {
    version = $3
    gsub(/"/, "", version)
    printf "%s\t%s\n", source, version
  }
' "$@" >"$work_dir/providers.tsv"

jq -Rrn '
  [inputs | split("\t") | {source: .[0], version: .[1]}]
  | if length == 0 then error("No providers found in tracked lock files") else . end
  | group_by(.source)[]
  | if all(.[]; (.source | test("^registry\\.terraform\\.io/[a-z0-9-]+/[a-z0-9-]+$"))
      and (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
    then . else error("Only stable providers from registry.terraform.io are supported") end
  | .[0].source as $source
  | map(.version | split(".") | map(tonumber)) as $versions
  | ($versions | map(.[0]) | unique) as $majors
  | if ($majors | length) != 1
    then error("Conflicting locked major versions for " + $source) else . end
  | [$source, ($majors[0] | tostring), ($versions | max | map(tostring) | join("."))]
  | @tsv
' "$work_dir/providers.tsv" >"$work_dir/providers-to-update.tsv"

tab=$(printf '\t')
while IFS="$tab" read -r source major current; do
  provider=${source#registry.terraform.io/}
  printf 'Checking provider releases: %s (major %s)\n' "$provider" "$major"
  curl --fail --silent --show-error \
    "https://registry.terraform.io/v1/providers/$provider/versions" \
    >"$work_dir/releases.json"
  latest=$(jq -er --argjson major "$major" --arg current "$current" '
    [.versions[]
      | select(.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
      | select((.version | split(".")[0] | tonumber) == $major)]
    | sort_by(.version | split(".") | map(tonumber))
    | if length == 0 then error("No stable release found in the current major") else . end
    | last.version
    | if (split(".") | map(tonumber)) < ($current | split(".") | map(tonumber))
      then error("Registry release would downgrade a locked provider") else . end
  ' "$work_dir/releases.json")
  printf '%s\t%s\t%s\n' "$provider" "$latest" "$((major + 1))" \
    >>"$work_dir/updates.tsv"
done <"$work_dir/providers-to-update.tsv"

while IFS="$tab" read -r provider latest next_major; do
  printf 'Updating provider constraints: %s -> %s\n' "$provider" "$latest"
  tfupdate provider --recursive --version "~> $latest" "$provider" infra/scenarios
  tfupdate provider --recursive --version ">= $latest, < $next_major.0.0" "$provider" infra/modules
done <"$work_dir/updates.tsv"
