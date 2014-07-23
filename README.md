# RethinkDB buildbot

The status page is available internally at http://dr-doom:8010/ and
externally at https://dr-doom.8010.dev.rethinkdb.com/

## Useful documentation

* Full buildbot documentation: http://docs.buildbot.net/0.8.8/full.html

## The `do` script

Used to automate common tasks

* Setup a virtualenv sandbox: `./do mk_sandbox && ./do install_deps`
* Set the remote url of origin to the buildbot master: `./do set-origin`
* Run a command on the master: `./do on_master`
* Smoke test the buildbot config: `./do checkconfig` or `./do in_sandbox buildbot checkconfig master`
* Send commands to the buildbot running on master: `./do stop`, `./do start`, `./do reconfig`
* Push your HEAD the to master's master branch: `./do push`
* Start a background ssh to speed up ssh: `./do background_ssh`

## Slaves

Instructions for adding a generic slave:

```
sudo useradd -m buildslave
sudo adduser buildslave remotelogin
sudo passwd buildslave
sudo apt-get install python-virtualenv python-dev
sudo -i -u buildslave
mkdir buildslave
virtualenv --no-site-packages .buildslave-sandbox
. .buildslave-sandbox/bin/activate
easy_install buildbot-slave
# buildslave create-slave buildslave dr-doom:9989 \`hostname\` \$PASSWORD
buildslave start buildslave
```

Startup on debian/ubuntu:

```
sudo apt-get install buildbot-slave
sudo tee /etc/default/buildslave << END
SLAVE_RUNNER=/home/buildslave/.buildslave-sandbox/bin/buildslave
SLAVE_ENABLED[1]=1
SLAVE_NAME[1]="RethinkDB build slave"
SLAVE_USER[1]="buildslave"
SLAVE_BASEDIR[1]="/home/buildslave/buildslave"
SLAVE_OPTIONS[1]=""
SLAVE_PREFIXCMD[1]=""
END
sudo /etc/init.d/buildslave start
EOF
}
```
