#!/bin/bash
set -e

if [ ! -z "${TRAVIS_TAG}" ]; then
    # Do not run for builds triggered by tagging.
    echo "Skipping $0 $@"
    exit 0
fi


# Get the HEAD commit ID for version.json in master branch if exists
BRANCH_INFO=`aws codecommit get-branch --repository-name $APP_MANIFEST_REPO --branch-name mainline`
if [ $? -ne 0 ]; then
    echo "Could not find mainline branch for repository $APP_MANIFEST_REPO. Creating first commit."
else
    export BRANCH_COMMIT_ID=`echo $BRANCH_INFO | jq -r '.branch.commitId'`
fi

export PARENT_COMMIT_FLAG=""
if [ -n "$BRANCH_COMMIT_ID" ]; then
    PARENT_COMMIT_FLAG="--parent-commit-id=$BRANCH_COMMIT_ID"
fi

if [ -z "$SA_VERSION" ]; then
    echo "No application version set, did add_tag run?"
    exit 1
fi

aws codecommit put-file --repository-name "$APP_MANIFEST_REPO" --branch-name mainline --file-content "{\"application_version\": \"$SA_VERSION\"}" --file-path "/version.json" --commit-message "Bumping version" --name "$GH_USER_NAME" --email "$GH_USER_EMAIL" $PARENT_COMMIT_FLAG