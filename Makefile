buildbot_version = 0.8.9

sandbox = . sandbox/bin/activate

default:

sandbox:
	virtualenv --no-site-packages sandbox

install-deps: sandbox
	$(sandbox) && easy_install sqlalchemy==0.7.10
	$(sandbox) && easy_install buildbot==$(buildbot_version)

start:
	$(sandbox) && buildbot start master
