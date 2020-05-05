#!/bin/bash
SRC_DIR='dist'
# name of branch to deploy to root of site
PRODUCTION_BRANCH='production'

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
	echo "skipping deploy to S3: this is a pull request"
	exit 0
fi

# extract current TAG if present
# the 2> is to prevent error messages when no match is found
CURRENT_TAG=`git describe --tags --exact-match $TRAVIS_COMMIT 2> /dev/null`

# strip PT ID from branch name for branch builds
DEPLOY_DIR_NAME=$TRAVIS_BRANCH
PT_PREFIX_REGEX="^([0-9]{8,}-)(.+)$"
PT_SUFFIX_REGEX="^(.+)(-[0-9]{8,})$"
if [[ $DEPLOY_DIR_NAME =~ $PT_PREFIX_REGEX ]]; then
  DEPLOY_DIR_NAME=${BASH_REMATCH[2]}
fi
if [[ $DEPLOY_DIR_NAME =~ $PT_SUFFIX_REGEX ]]; then
  DEPLOY_DIR_NAME=${BASH_REMATCH[1]}
fi

# tagged builds deploy to /version/TAG_NAME
if [ "$TRAVIS_BRANCH" = "$CURRENT_TAG" ]; then
  mkdir -p _site/version
  S3_DEPLOY_DIR="version/$TRAVIS_BRANCH"
  DEPLOY_DEST="_site/$S3_DEPLOY_DIR"
  # used by s3_website.yml
  export S3_DEPLOY_DIR

# production branch builds deploy to root of site
elif [ "$TRAVIS_BRANCH" = "$PRODUCTION_BRANCH" ]; then
  DEPLOY_DEST="_site"
# branch builds deploy to /branch/BRANCH_NAME
else
  mkdir -p _site/branch
  S3_DEPLOY_DIR="branch/$DEPLOY_DIR_NAME"
  DEPLOY_DEST="_site/$S3_DEPLOY_DIR"
  # used by s3_website.yml
  export S3_DEPLOY_DIR
fi

# copy files to destination
mv $SRC_DIR $DEPLOY_DEST

# deploy the site contents
s3_website push --site _site
