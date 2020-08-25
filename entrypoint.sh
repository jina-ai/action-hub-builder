#!/usr/bin/env bash

set -ex

URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${{ github.event.pull_request.number }}/files"
FILES=$(curl -s -X GET -G $URL | jq -c '.[] | select( .filename | endswith("manifest.yml")) | .filename | rtrimstr("manifest.yml")')
if [ -z "$FILES" ]
then
      echo "nothing to build"
else
      echo "something to build:"
      for TAR in $FILES
      do
        echo $TAR
      done
fi