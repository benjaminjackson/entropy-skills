#!/bin/sh
# Prints one telegram when .entropy/current.json exists in the project. Silent otherwise.
cwd=$(jq -r '.cwd // empty')
f="$cwd/.entropy/current.json"
[ -f "$f" ] || exit 0
scope=$(jq -r '.scope // "everything"' "$f")
echo "SEED ACTIVE STOP SCOPE $scope STOP READ .entropy/current.json BEFORE IN-SCOPE DECISIONS STOP"
