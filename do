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
    hash virtualenv 2>/dev/null || { echo >&2 "The Python virtualenv module is required but does not seem to be available"; exit 1; }
    virtualenv --no-site-packages sandbox
}

in_sandbox () (
    if [[ ! -d "$root"/sandbox ]]; then
        mk_sandbox
    fi
    set +eu
    . "$root"/sandbox/bin/activate
    "$@"
)

install_deps () {
    in_sandbox easy_install --quiet sqlalchemy==0.7.10
    in_sandbox easy_install --quiet buildbot==$buildbot_version
    in_sandbox easy_install --quiet buildbot-slave==$buildbot_version
    in_sandbox easy_install --quiet requests
}

set-origin () {
    git remote set-url origin $master_full
}

on_master () {
    $ssh $master_ssh "cd $master_path && ./do in_sandbox $(printf "%q " "$@")"
}

put_on_master () {
    cat "$1" | on_master bash -c 'cat > "$1"' -- "$1"
}

start () {
    on_master buildbot start master
}

stop () {
    on_master buildbot stop master
}

checkconfig () {
    if [[ ! -f master/config.py ]] || [[ `head -n 1 "$root"/master/config.py` =~ ^#\ dummy\ config.py\ file ]]; then
        # write a dummy config.py
        templateContents=`cat "$root"/master/config.py.template`
        printf "# dummy config.py file created by the do command\n\n$templateContents\n" > "$root"/master/config.py
    fi
    install_deps
    in_sandbox buildbot checkconfig master
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

ask () {
    local ans
    echo -n "$1 "
    read ans
    echo -n "$ans"
}

"$@"
