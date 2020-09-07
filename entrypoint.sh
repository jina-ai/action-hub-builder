#!/usr/bin/env bash

set -ex

pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pull_number}/files"
FILES=$(curl -s -X GET -G $URL | jq -r '.[] | select( (.filename | endswith("manifest.yml")) and (.status != "removed")) | .filename | rtrimstr("manifest.yml")')

rc=0
SUCCESS_TARGETS=()
FAILED_TARGETS=()
if [ -z "$FILES" ]
then
      echo "nothing to build"
else
      echo "targets to build: $FILES"
      for TAR_PATH in $FILES
      do
        if jina hub build $TAR_PATH --pull --prune-images --test-uses --raise-error --daemon; then
          SUCCESS_TARGETS+=("$TAR_PATH")
        else
          FAILED_TARGETS+=("$TAR_PATH")
          rc=1
        fi
      done
fi
echo "SUCCESS_TARGETS: $SUCCESS_TARGETS"
echo "FAILED_TARGETS: $FAILED_TARGETS"
echo "::set-output name=success_targets::$SUCCESS_TARGETS"
echo "::set-output name=failed_targets::$FAILED_TARGETS"
exit $rc