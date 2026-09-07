#!/usr/bin/env bash
# Delete container image versions older than MAX_AGE_DAYS from GHCR.
#
# Two things survive regardless of age:
#   - latest
#   - every digest referenced by a version that is itself surviving
# The second rule is what keeps a multi-arch build intact. Per-platform manifests
# and attestations carry no tag of their own, and an unchanged one keeps the
# created_at of the first push that produced it, so a recent index can point at a
# digest that looks months old. Deleting it would gut a live image.
#
#   DRY_RUN=true .github/scripts/cleanup-old-images.sh
#
# Needs the read:packages scope to list, and delete:packages to delete.
set -euo pipefail

REGISTRY="${REGISTRY:-ghcr.io}"
MAX_AGE_DAYS="${MAX_AGE_DAYS:-90}"
DRY_RUN="${DRY_RUN:-true}"

# Set by Actions; outside of it, fall back to the checked out repository.
if [ -z "${GITHUB_REPOSITORY:-}" ]; then
  GITHUB_REPOSITORY=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
fi

repo=$(printf '%s' "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')
versions="/orgs/${repo%%/*}/packages/container/${repo#*/}/versions"

# GNU date on the runner, BSD date on macOS.
cutoff=$(date -u -d "${MAX_AGE_DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -u -v-"${MAX_AGE_DAYS}"d +%Y-%m-%dT%H:%M:%SZ)

# Every digest a manifest mentions: platform manifests, attestations, layers, config.
# Grepping the raw manifest keeps this dumb on purpose. Layer digests are never
# package versions, so protecting them too costs nothing.
# A manifest that is already gone mentions nothing; any other failure means we
# cannot tell what is referenced, so the caller has to stop.
referenced_by() {
  local out
  if out=$(docker buildx imagetools inspect "${REGISTRY}/${repo}@${1}" --raw 2>&1); then
    printf '%s' "$out" | grep -o 'sha256:[0-9a-f]\{64\}' || true
  elif printf '%s' "$out" | grep -qiE 'not found|manifest unknown|MANIFEST_UNKNOWN'; then
    return 0
  else
    echo "error: cannot inspect ${1}: ${out}" >&2
    return 1
  fi
}

echo "Package: ${REGISTRY}/${repo}"
echo "Cutoff:  ${cutoff}"
echo "Dry run: ${DRY_RUN}"
echo

if ! list=$(gh api --paginate "$versions" \
  --jq '.[] | [.id, .name, .created_at, (.metadata.container.tags // [] | join(","))] | @tsv'); then
  echo "error: cannot list versions of ${repo}" >&2
  exit 1
fi

# Mark: a tag is the only way to pull an image, so anything reachable from one is live.
keep=""
roots=0
while IFS="$(printf '\t')" read -r id digest created tags; do
  [ -n "$tags" ] || continue

  roots=$((roots + 1))
  if ! children=$(referenced_by "$digest"); then
    echo "refusing to delete anything" >&2
    exit 1
  fi
  keep="${keep}
${digest}
${children}"
done <<EOF
${list}
EOF

if [ "$roots" -eq 0 ]; then
  echo "error: package has no tags, refusing to delete anything" >&2
  exit 1
fi
echo "Keeping $(printf '%s' "$keep" | grep -o 'sha256:[0-9a-f]*' | sort -u | wc -l | tr -d ' ')" \
     "digest(s) reachable from ${roots} tag(s)"

# Sweep: old and unreachable.
expired=0
while IFS="$(printf '\t')" read -r id digest created tags; do
  [ -n "$id" ] || continue
  [[ "$created" < "$cutoff" ]] || continue
  case "$keep" in *"$digest"*) continue ;; esac

  expired=$((expired + 1))
  if [ "$DRY_RUN" = "true" ]; then
    echo "would delete $digest (created $created)"
  else
    echo "deleting $digest (created $created)"
    gh api -X DELETE "${versions}/${id}" --silent
  fi
done <<EOF
${list}
EOF

echo
echo "${expired} version(s) older than ${MAX_AGE_DAYS} days."
