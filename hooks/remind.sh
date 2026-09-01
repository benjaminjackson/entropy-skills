#!/bin/sh
# Prints one telegram when .entropy/current.json exists in the project. Silent otherwise.
# Scope is capped and flattened: the file may come from a cloned repo, so its text is not trusted.
cwd=$(jq -r '.cwd // empty')
f="$cwd/.entropy/current.json"
[ -f "$f" ] || exit 0
scope=$(jq -r '.scope // "everything"' "$f" | tr -d '\n\r' | cut -c1-80)
echo "SEED ACTIVE STOP SCOPE $scope STOP READ .entropy/current.json BEFORE IN-SCOPE DECISIONS STOP"
