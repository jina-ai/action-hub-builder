#!/usr/bin/env bash

set -ex
rc=0

export IS_PUSH=$1
export GITHUB_TOKEN=$2
export DOCKERHUB_USERNAME=$3
export DOCKERHUB_PASSWORD=$4
export DOCKERHUB_REGISTRY=$5
export JINAHUB_SLACK_WEBHOOK=$6
export JINA_VERSION=$7

if [ "$JINA_VERSION" != "latest" ]; then
  pip install "jina==${JINA_VERSION}"
else
  pip install jina --no-cache-dir
fi

pull_number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

PR_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pull_number}"
FILES_URL=${PR_URL}/files
AUTHOR=$(curl -s -X GET $PR_URL | jq -r '.user.login')
FILENAME=files_in_pr.json

# if we don't have the token
if [ -z "$GITHUB_TOKEN" ]; then
  curl -s -X GET -G $FILES_URL > $FILENAME
else
  curl -s -X GET -G -H "Authorization: token $GITHUB_TOKEN" $FILES_URL > $FILENAME
fi

if [[ "$AUTHOR" == "dependabot[bot]" ]]; then
  # If author is dependabot, we want to push files to hub, even if the modified files are dockerfile / requirement.txt
  manifest_files=$(cat $FILENAME | jq -r '.[] | select( (.filename | endswith("manifest.yml")) and (.status != "removed")) | .filename | rtrimstr("manifest.yml")')
  docker_files=$(cat $FILENAME | jq -r '.[] | select( (.filename | endswith("Dockerfile")) and (.status != "removed")) | .filename | rtrimstr("Dockerfile")')
  requirements_files=$(cat $FILENAME | jq -r '.[] | select( (.filename | endswith("requirements.txt")) and (.status != "removed")) | .filename | rtrimstr("requirements.txt")')
  all_files=("${manifest_files[@]}" "${docker_files[@]}" "${requirements_files[@]}")
  # get unique entries in all_files
  FILES=$(echo "${all_files[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
else
  FILES=$(cat $FILENAME | jq -r '.[] | select( (.filename | endswith("manifest.yml")) and (.status != "removed")) | .filename | rtrimstr("manifest.yml")')
fi

rc=0
SUCCESS_TARGETS=()
FAILED_TARGETS=()

ACCESS_DIRECTORY=~/.jina
ACCESS_FILE=~/.jina/access.yml

if [ -z "$FILES" ]; then
    echo "nothing to build"
    rc=1
else
    echo "targets to build: $FILES"
    for TAR_PATH in $FILES; do

      mkdir -p ${ACCESS_DIRECTORY}
      if [ ! -f ${ACCESS_FILE} ]; then touch ${ACCESS_FILE}; echo "access_token: ${GITHUB_TOKEN}" >> ${ACCESS_FILE}; fi

      cmd="jina hub build --pull --prune-images --raise-error --host-info --test-uses --timeout-ready 30000"
      if [[ "$IS_PUSH" == true ]]; then
        cmd="$cmd --push $TAR_PATH"

        # only add args when not empty
        [ ! -z "$DOCKERHUB_USERNAME" ] && cmd="$cmd --username $DOCKERHUB_USERNAME"
        [ ! -z "$DOCKERHUB_PASSWORD" ] && cmd="$cmd --password $DOCKERHUB_PASSWORD"
        [ ! -z "$DOCKERHUB_REGISTRY" ] && cmd="$cmd --registry $DOCKERHUB_REGISTRY"
      else
        cmd="$cmd --daemon $TAR_PATH"
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
