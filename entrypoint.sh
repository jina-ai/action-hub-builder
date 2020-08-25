#!/usr/bin/env bash

set -ex

pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pull_number}/files"
FILES=$(curl -s -X GET -G $URL | jq -r '.[] | select( .filename | endswith("manifest.yml")) | .filename | rtrimstr("manifest.yml")')

rc=0
if [ -z "$FILES" ]
then
      echo "nothing to build"
else
      echo "targets to build: $FILES"
      for TAR in $FILES
      do
        jina hub build $TAR || rc=$?
      done
fi
exit $rc