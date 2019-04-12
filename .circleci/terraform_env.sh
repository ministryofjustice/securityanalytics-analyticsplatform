#!/usr/bin/sh

# Get short version of git hash for temporary deployment
export SOURCE_VERSION=`git rev-parse HEAD`
export DEPLOY_STAGE=$(expr substr $SOURCE_VERSION 1 8)

# TODO change this when we have more stages than just dev
export SSM_SOURCE_STAGE=dev