import json
import requests

# See http://docs.buildbot.net/0.8.4/reference/buildbot.interfaces.IStatusReceiver-class.html

from zope.interface import implements
from buildbot.status.base import StatusReceiverMultiService
from buildbot.interfaces import IStatusReceiver
from twisted.python import log

def link(url, text):
    if text:
        return '<%s|%s>' % (url, text)
    else:
        return '<%s>' % (url,)

def attachment(fallback, pretext=None, color=None, fields=None):
    fields = [('fallback', fallback), ('pretext', pretext), ('color', color), ('fields', fields)]
    return {k: v for k, v in fields if v is not None}

def field(title, value=None, short=None):
    fields = [('title', title), ('value', value), ('short', short)]
    return {k: v for k, v in fields if v is not None}

class Slack(StatusReceiverMultiService):
    implements(IStatusReceiver)

    def __init__(self, webhook):
        log.msg('Slack: __init__')
        StatusReceiverMultiService.__init__(self)
        self.webhook = webhook

    def send(self, text=None, payload=None, attachments=None):
        if payload is None:
            fields = [('text', text), ('attachments', attachments)]
            payload = {k: v for k, v in fields if v is not None}
        log.msg('Slack: send ' + json.dumps(payload))
        res = requests.post(self.webhook, data={'payload': json.dumps(payload)})
        res.raise_for_status()

    def builderAdded(self, name, builder):
        log.msg('Slack: builderAdded')
        return self

    def startService(self):
        log.msg('Slack: startService')
        StatusReceiverMultiService.startService(self)
        self._status = self.parent.getStatus()
        self._status.subscribe(self)

    def stopService(self):
        log.msg('Slack: stopService')
        StatusReceiverMultiService.stopService(self)
        self._status.unsubscribe(self)
