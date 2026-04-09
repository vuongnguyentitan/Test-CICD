#!/usr/bin/env bash
set -euo pipefail

: "${UPLOAD_DIR:?UPLOAD_DIR is required}"
: "${GITHUB__JSON_SECRETS:?GITHUB__JSON_SECRETS is required}"
: "${SERVICE_PREFIX:?SERVICE_PREFIX is required}"
: "${DOT_ENV_TEMPLATE:?DOT_ENV_TEMPLATE is required}"

mkdir -p "$UPLOAD_DIR" && cd "$UPLOAD_DIR"

prefix="${SERVICE_PREFIX}__"

vars=$(echo "$GITHUB__JSON_SECRETS" | jq -r --arg p "$prefix" '
  to_entries
  | map(select(.key | startswith($p)))
  | .[].key
')

# export secrets
for v in $vars; do
  export "$v=$(echo "$GITHUB__JSON_SECRETS" | jq -r --arg k "$v" '.[$k]')"
  [ -z "${!v}" ] && echo "Missing $v" && exit 1
done

# build .env
printf "%s" "$DOT_ENV_TEMPLATE" > .env
envsubst "$(printf '$%s ' $vars)" < .env > .env.tmp
mv .env.tmp dotenvfile.txt
