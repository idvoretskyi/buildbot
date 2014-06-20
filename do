#!/bin/bash

set -eu

buildbot_version=0.8.9

master_login=buildbot
master_host=dr-doom
master_path=buildbot

master_ssh=$master_login@$master_host
master_full=$master_ssh:$master_path

mk_sandbox () {
  virtualenv --no-site-packages sandbox
}

in_sandbox () (
    . "$(dirname "$0")/sandbox/bin/activate"
    "$@"
)

install_deps () {
  in_sandbox easy_install sqlalchemy==0.7.10
  in_sandbox easy_install buildbot==$buildbot_version
  in_sandbox easy_install buildbot-slave==$buildbot_version
}

set-origin () {
  git remote set-url origin $master_full
}

on_master () {
    ssh $master_ssh "cd $master_path && $(printf "%q " "$@")"
}

start () {
  on_master ./do in_sandbox buildbot start master
}

stop () {
  on_master ./do in_sandbox buildbot stop master
}

reconfig () {
  on_master ./do in_sandbox buildbot reconfig master
}

"$@"
