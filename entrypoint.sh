#!/usr/bin/env bash

set -ex
rc=0

export IS_PUSH=$1
export DOCKERHUB_USERNAME=$2
export DOCKERHUB_PASSWORD=$3
export DOCKERHUB_REGISTRY=$4
export JINAHUB_SLACK_WEBHOOK=$5
export GITHUB_TOKEN=$6

pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pull_number}/files"
FILES=$(curl -s -X GET -G $URL | jq -r '.[] | select( (.filename | endswith("manifest.yml")) and (.status != "removed")) | .filename | rtrimstr("manifest.yml")')

rc=0
SUCCESS_TARGETS=()
FAILED_TARGETS=()

ACCESS_DIRECTORY: ~/.jina
ACCESS_FILE: ~/.jina/access.yml

if [ -z "$FILES" ]; then
    echo "nothing to build"
else
    echo "targets to build: $FILES"
    for TAR_PATH in $FILES; do
    
      mkdir -p ${ACCESS_DIRECTORY}
      if [ ! -f ${ACCESS_FILE} ]; then touch ${ACCESS_FILE}; echo "access_token: ${GITHUB_TOKEN}" >> ${ACCESS_FILE}; fi

      cmd="jina hub build --pull --prune-images --raise-error --host-info"
      if [[ "$IS_PUSH" == true ]]; then
        cmd="$cmd --push $TAR_PATH"

        # only add args when not empty
        [ ! -z "$DOCKERHUB_USERNAME" ] && cmd="$cmd --username $DOCKERHUB_USERNAME"
        [ ! -z "$DOCKERHUB_PASSWORD" ] && cmd="$cmd --password $DOCKERHUB_PASSWORD"
        [ ! -z "$DOCKERHUB_REGISTRY" ] && cmd="$cmd --registry $DOCKERHUB_REGISTRY"
      else
        cmd="$cmd --test-uses --daemon $TAR_PATH"
      fi

      if ($cmd); then
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