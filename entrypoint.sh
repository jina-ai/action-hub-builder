#!/usr/bin/env bash

set -ex
rc=0

if [ "$#" -ne 9 ]; then
  echo "Expected 9 parameters. Got $#"
  echo "./entrypoint.sh IS_CLI DOCKERHUB_USERNAME DOCKERHUB_PASSWORD DOCKERHUB_REGISTRY JINA_DB_HOSTNAME JINA_DB_USERNAME JINA_DB_PASSWORD JINA_DB_NAME JINA_DB_COLLECTION"
  exit 1
fi

export IS_CLI=$1
export DOCKERHUB_USERNAME=$2
export DOCKERHUB_PASSWORD=$3
export DOCKERHUB_REGISTRY=$4
export JINA_DB_HOSTNAME=$5
export JINA_DB_USERNAME=$6
export JINA_DB_PASSWORD=$7
export JINA_DB_NAME=$8
export JINA_DB_COLLECTION=$9

pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pull_number}/files"
FILES=$(curl -s -X GET -G $URL | jq -r '.[] | select( (.filename | endswith("manifest.yml")) and (.status != "removed")) | .filename | rtrimstr("manifest.yml")')

rc=0
SUCCESS_TARGETS=()
FAILED_TARGETS=()
if [ -z "$FILES" ]; then
    echo "nothing to build"
else
    echo "targets to build: $FILES"
    for TAR_PATH in $FILES; do
        if [[ "$IS_CLI" == "True" ]]; then
            if jina hub build --pull --prune-images --test-uses --raise-error --daemon $TAR_PATH; then
                SUCCESS_TARGETS+=("$TAR_PATH")
            else
                FAILED_TARGETS+=("$TAR_PATH")
                rc=1
            fi
        else
            if jina hub build --push --username $DOCKERHUB_USERNAME --password $DOCKERHUB_PASSWORD --registry $DOCKERHUB_REGISTRY --prune-images --raise-error --daemon $TAR_PATH; then
                SUCCESS_TARGETS+=("$TAR_PATH")
            else
                FAILED_TARGETS+=("$TAR_PATH")
                rc=1
            fi
        fi
    done
fi
echo "SUCCESS_TARGETS: $SUCCESS_TARGETS"
echo "FAILED_TARGETS: $FAILED_TARGETS"
echo "::set-output name=success_targets::$SUCCESS_TARGETS"
echo "::set-output name=failed_targets::$FAILED_TARGETS"
exit $rc