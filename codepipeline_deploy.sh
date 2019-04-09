#!/bin/bash
set -e

if [ ! -z "${TRAVIS_TAG}" ]; then
    # Do not run for builds triggered by tagging.
    echo "Skipping $0 $@"
    exit 0
fi


# Get the HEAD commit ID for version.json in master branch if exists
BRANCH_INFO=`aws codecommit get-branch --repository-name $CC_REPO_NAME --branch-name mainline`
if [ $? -ne 0 ]; then
    echo "Could not find mainline branch for repository $CC_REPO_NAME. Creating first commit."
else
    export BRANCH_COMMIT_ID=`echo $BRANCH_INFO | jq -r '.branch.commitId'`
fi

export PARENT_COMMIT_FLAG=""
if [ -z "$BRANCH_COMMIT_ID" ]; then
    PARENT_COMMIT_FLAG="--parent-commit-id=$BRANCH_COMMIT_ID"

aws codecommit put-file --repository-name "$CC_REPO_NAME" --branch-name mainline --file-content '{"application_version": "1.0.0.1"}' --file-path "/version.json" --commit-message "Bumping version" --name "$GH_USER_NAME" --email "$GH_USER_EMAIL" $PARENT_COMMIT_FLAG


# Move artifacts to shared/<version>/ and version.json to shared/
mkdir $SA_VERSION && mv $TRAVIS_BUILD_DIR/shared/* $SA_VERSION && mv $SA_VERSION $TRAVIS_BUILD_DIR/shared/
cp "$TRAVIS_BUILD_DIR/version.json" "$TRAVIS_BUILD_DIR/shared/version.json"
ls "$TRAVIS_BUILD_DIR"
echo -----
ls $TRAVIS_BUILD_DIR
echo -----
ls "$TRAVIS_BUILD_DIR/shared"
echo here

exit 0
# Clone the CC repository where version.json lives and commit the version.json file produced by current build
git clone "$CC_REPO_CLONE_URL_HTTP" cc-repo-for-version-file
cd cc-repo-for-version-file
cp "$TRAVIS_BUILD_DIR/shared/version.json" version.json
git add version.json
git commit -m "updating version.json file by commitId: $TRAVIS_COMMIT_MESSAGE"
git push
