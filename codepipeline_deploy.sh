#!/bin/bash
# set -e

if [ ! -z "${TRAVIS_TAG}" ]; then
    # Do not run for builds triggered by tagging.
    echo "Skipping $0 $@"
    exit 0
fi


echo "Running codepipeline_deploy with repo $APP_MANIFEST_REPO"

# Get the HEAD commit ID for version.json in master branch if exists
BRANCH_INFO=`aws codecommit get-branch --repository-name $APP_MANIFEST_REPO --branch-name mainline`
if [ $? -ne 0 ]; then
    echo "Could not find mainline branch for repository $APP_MANIFEST_REPO. Creating first commit."
else
    export BRANCH_COMMIT_ID=`echo $BRANCH_INFO | jq -r '.branch.commitId'`
fi

echo "Branch info: $BRANCH_INFO"
echo "Branch commit id: $BRANCH_COMMIT_ID"

export PARENT_COMMIT_FLAG=""
if [ -n "$BRANCH_COMMIT_ID" ]; then
    PARENT_COMMIT_FLAG="--parent-commit-id=$BRANCH_COMMIT_ID"
fi

echo "Parent commit flag: $PARENT_COMMIT_FLAG"

VERSION_FILE_CONTENTS=`cat $TRAVIS_BUILD_DIR/version.json`
echo "File contents: $VERSION_FILE_CONTENTS"

echo "New Sample app version: $SA_VERSION"

if [ -z "$SA_VERSION" ]; then
    echo "No application version set, did add_tag run?"
    exit 1
fi

aws codecommit put-file --repository-name "$APP_MANIFEST_REPO" --branch-name mainline --file-content "{\"application_version\": \"$SA_VERSION\"}" --file-path "/version.json" --commit-message "Bumping version" --name "$GH_USER_NAME" --email "$GH_USER_EMAIL" $PARENT_COMMIT_FLAG


# Move artifacts to shared/<version>/ and version.json to shared/
echo "Build dir contents:"
ls "$TRAVIS_BUILD_DIR"
mkdir $SA_VERSION && mv $TRAVIS_BUILD_DIR/shared/* $SA_VERSION && mv $SA_VERSION $TRAVIS_BUILD_DIR/shared/
cp "$TRAVIS_BUILD_DIR/version.json" "$TRAVIS_BUILD_DIR/shared/version.json"
echo -----
ls $TRAVIS_BUILD_DIR
echo -----
ls "$TRAVIS_BUILD_DIR/shared"
echo here

# exit 0
# # Clone the CC repository where version.json lives and commit the version.json file produced by current build
# git clone "$CC_REPO_CLONE_URL_HTTP" cc-repo-for-version-file
# cd cc-repo-for-version-file
# cp "$TRAVIS_BUILD_DIR/shared/version.json" version.json
# git add version.json
# git commit -m "updating version.json file by commitId: $TRAVIS_COMMIT_MESSAGE"
# git push