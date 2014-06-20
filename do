#!/bin/bash

set -eu

buildbot_version=0.8.9

master_login=buildbot
master_host=dr-doom
master_path=buildbot

master_ssh=$master_login@$master_host
master_full=$master_ssh:$master_path

root=$(dirname "$0")

ssh_master="ssh -o ControlMaster=auto -o ControlPath=$root/.ssh-master"

if [[ -e "$root"/.ssh-master ]]; then
    ssh=$ssh_master
else
    ssh=ssh
fi

mk_sandbox () {
    virtualenv --no-site-packages sandbox
}

in_sandbox () (
    set +eu
    . "$root"/sandbox/bin/activate
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
    $ssh -v $master_ssh "cd $master_path && ./do in_sandbox $(printf "%q " "$@")"
}

start () {
    on_master buildbot start master
}

stop () {
    on_master buildbot stop master
}

reconfig () {
    on_master buildbot reconfig master
}

push () {
    local id=$(cd "$root" && git rev-parse HEAD)
    git push origin HEAD:refs/pushed/$id
    on_master git merge --ff-only refs/pushed/$id
    git push origin :refs/pushed/$id
}

push_reconfig () {
    push
    reconfig
}

background_ssh () {
    if [[ -e "$root"/.ssh-master ]]; then
        echo .ssh-master already exists
    else
        $ssh_master -fMN $master_ssh
    fi
}

"$@"