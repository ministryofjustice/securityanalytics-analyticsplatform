#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Syntax: setup.sh <app_name> <tf_workspace>"
    sleep 30
    exit
fi
# update with the latest shared code first:
git submodule init
git submodule update --remote
git submodule sync

export PIPENV_VENV_IN_PROJECT=true
pipenv install --dev
pipenv run ./pipenv.sh $1 $2

wait