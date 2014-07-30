# RethinkDB buildbot

## Web status page

The status page is available internally at [http://dr-doom:8010/](http://dr-doom:8010/) and
externally at https://dr-doom.8010.dev.rethinkdb.com/

The style and content of the status page can be changed by editing the
files in `master/public_html/` and `master/templates/`

## Modifying the buildbot configuration

Check out this repo from dr-doom, and add a github remote:

```
git clone buildbot@dr-doom:buildbot
git remote add git@github.com:rethinkdb/
```

If the dr-doom HEAD and github HEAD are not in sync, someone else is
working on the buildbot configuration. Coordinate your changes to
avoid conflicts.

* Before pushing, `./do checkconfig` should say `Config file is good!`
* Commit your changes locally `git commit -m 'descriptive message'`
* Push the changes to buildbot@dr-doom:buildbot `./do push`
* Tell the running buildbot to reload the configuration file `./do reconfig`
* Check that your changes work, perhaps by triggering some builds on http://dr-doom:8010
* Push to github. `git push github master`

## Useful documentation

* Single page buildbot documentation: http://docs.buildbot.net/0.8.8/full.html
* Buildbot documentation index: http://docs.buildbot.net/0.8.9/genindex.html

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
