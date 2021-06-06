#!/bin/bash

# Copy the yaml files from backup folder to manifests folder

if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1

cp -fr ./manifests_bkup/*.yaml ./manifests/.


gsed -i "s/GUID/$GUID/g" ./manifests/*.yaml
