#!/bin/bash

set -eu

buildbot_version=0.8.9

master_login=buildbot
master_host=dr-doom
master_path=buildbot

master_ssh=$master_login@$master_host
master_full=$master_ssh:$master_path
master_url=http://$master_host:8010

root=$(dirname "$0")

ssh_master="ssh -o ControlMaster=auto -o ControlPath=$root/.ssh-master"

if [[ -e "$root"/.ssh-master ]]; then
    ssh=$ssh_master
else
    ssh=ssh
fi

do_mk_sandbox () {
    hash virtualenv 2>/dev/null || { echo >&2 "The Python virtualenv module is required but does not seem to be available"; exit 1; }
    virtualenv --no-site-packages sandbox
}

do_in_sandbox () (
    if [[ ! -d "$root"/sandbox ]]; then
        do_mk_sandbox
    fi
    set +eu
    . "$root"/sandbox/bin/activate
    "$@"
)

do_install_deps () {
    do_in_sandbox easy_install --quiet sqlalchemy==0.7.10
    do_in_sandbox easy_install --quiet buildbot==$buildbot_version
    do_in_sandbox easy_install --quiet buildbot-slave==$buildbot_version
    do_in_sandbox easy_install --quiet requests
}

do_set-origin () {
    git remote set-url origin $master_full
}

do_on_master () {
    $ssh $master_ssh "cd $master_path && ./do in_sandbox $(printf "%q " "$@")"
}

do_put_on_master () {
    cat "$1" | on_master bash -c 'cat > "$1"' -- "$1"
}

do_start () {
    do_on_master buildbot start master
}

do_stop () {
    do_on_master buildbot stop master
}

do_checkconfig () {
    if [[ ! -f master/config.py ]] || [[ `head -n 1 "$root"/master/config.py` =~ ^#\ dummy\ config.py\ file ]]; then
        # write a dummy config.py
        templateContents=`cat "$root"/master/config.py.template`
        printf "# dummy config.py file created by the do command\n\n$templateContents\n" > "$root"/master/config.py
    fi
    do_in_sandbox buildbot checkconfig master
}

do_reconfig () {
    do_on_master buildbot reconfig master
}

do_push () {
    local id=$(cd "$root" && git rev-parse HEAD)
    git push origin HEAD:refs/pushed/$id
    do_on_master git merge --ff-only refs/pushed/$id
    git push origin :refs/pushed/$id
}

do_push_reconfig () {
    do_push
    do_reconfig
}

do_background_ssh () {
    if [[ -e "$root"/.ssh-master ]]; then
        echo .ssh-master already exists
    else
        $ssh_master -fMN $master_ssh
    fi
}

do_logs () {
  do_on_master tail -n 100 -f master/twistd.log
}

do_login () {
    echo -n 'Password: '; read -sr password; echo
    curl -XPOST $master_url/login -d "username=rethinkdb&passwd=$password" -c .login.cookie; echo
}

do_curl () {
    path=$1; shift
    curl --silent -b .login.cookie "$master_url/$path" "$@"
    echo
}

json () {
    python -c '
import json, sys, types
data = json.loads(sys.stdin.read())
for k in "'"$2"'".split("/"):
  if k:
    data = data[k]
res = '"${1:-data}"'
try:
  assert not isinstance(res, types.StringTypes)
  it = iter(res)
except:
  print res
else:
  for x in it:
    print x'
}

do_json-api () {
    do_curl "json/$1?as_text=1&select=${2:-}"
}

do_api () {
    do_curl "json/$1" | json "${3:-data}" "${2:-}"
}

do_list-builders () {
    do_api builders
}

do_force () {
    reason="($USER)+./do+force+${2:-}"
    do_curl builders/$1/force -XPOST -d "forcescheduler=force-$1&reason=$reason&rethinkdb_branch=${2:-next}"
}

cmd=$1
shift
"do_$cmd" "$@"
