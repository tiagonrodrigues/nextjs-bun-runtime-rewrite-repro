#!/usr/bin/env bash
# Usage: ./check.sh https://your-deployment.vercel.app [iterations]
# Requests the unprefixed and prefixed variants of the same routes and reports
# how often the returned <title> is not the one the route should render.
set -u
BASE="${1:?usage: ./check.sh <base-url> [iterations]}"
N="${2:-40}"
declare -A EXPECT=( ["/alpha"]="ALPHA PAGE" ["/beta"]="BETA PAGE" ["/gamma"]="GAMMA PAGE"
                    ["/pt/alpha"]="ALPHA PAGE" ["/pt/beta"]="BETA PAGE" ["/pt/gamma"]="GAMMA PAGE" )
declare -A BAD TOT
for ((i=1;i<=N;i++)); do
  for path in "${!EXPECT[@]}"; do
    code=$(curl -s -o /tmp/_r.html -w '%{http_code}' "$BASE$path")
    title=$(sed -n 's/.*<title>\([^<]*\).*/\1/p' /tmp/_r.html | head -1)
    TOT[$path]=$(( ${TOT[$path]:-0} + 1 ))
    if [[ "$code" != "200" || "$title" != "${EXPECT[$path]}" ]]; then
      BAD[$path]=$(( ${BAD[$path]:-0} + 1 ))
      echo "  MISMATCH $path -> HTTP $code, title '$title' (expected '${EXPECT[$path]}')"
    fi
  done
done
echo
printf '%-14s %8s %8s\n' route requests failures
for path in "${!EXPECT[@]}"; do
  printf '%-14s %8s %8s\n' "$path" "${TOT[$path]:-0}" "${BAD[$path]:-0}"
done
