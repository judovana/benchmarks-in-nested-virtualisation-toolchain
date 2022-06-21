#!/bin/bash
set -exo pipefail

echo test
FILE=~/.ssh/tester_rsa
if [ -f "$FILE" ]; then
    echo "$FILE alredy exists."
else
    pushd ~/.ssh && ln -s id_rsa tester_rsa
fi

