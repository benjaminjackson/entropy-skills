#!/bin/sh
# Prints one telegram when .entropy/current.json exists in the project. Silent otherwise.
# Nothing from the file is echoed: it may come from a cloned repo, so its text is not trusted.
cwd=$(jq -r '.cwd // empty')
[ -f "$cwd/.entropy/current.json" ] || exit 0
echo "SEED ACTIVE STOP READ .entropy/current.json FOR SCOPE AND DIRECTION BEFORE IN-SCOPE DECISIONS STOP"
