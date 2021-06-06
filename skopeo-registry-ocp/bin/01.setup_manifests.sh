#!/bin/bash

# Copy the yaml files from backup folder to manifests folder

if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID $GIT_REPO $JENKINS_FILE_PATH"
    exit 1
fi

GUID=$1
GIT_REPO=$2
JENKINS_FILE_PATH=$3

cp -fr ./manifests_template/*.yaml ./manifests/.
cp -fr ./manifests_template/*.yml ./manifests/.

#When using on MAC, use gsed. On Linux use sed
gsed -i "s/GUID/$GUID/g" ./manifests/*.yaml
gsed -i "s/GUID/$GUID/g" ./manifests/*.yml

#These may error out and need to be updated manually
gsed -i "s, GIT_REPO, $GIT_REPO, g" ./manifests/*.yaml
gsed -i "s, GIT_REPO, $GIT_REPO, g" ./manifests/*.yaml
gsed -i "s, JENKINS_FILE_PATH, $JENKINS_FILE_PATH, g" ./manifests/*.yaml
gsed -i "s, JENKINS_FILE_PATH, $JENKINS_FILE_PATH, g" ./manifests/*.yaml
