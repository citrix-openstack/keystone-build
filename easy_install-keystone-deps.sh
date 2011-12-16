#!/bin/sh

set -ex

MOCK="$1"

# Keystone dependencies
# OS-158: install patched version of eventlet-0.9.14 from packages.hg rather than eventlet==0.9.13
$MOCK --chroot "easy_install-2.6 -vvv -H None -f /eggs -z \
                httplib2==0.6.0 \
                IPy==0.72 \
                lxml==2.3 \
                passlib==1.5.3 \
                Paste==1.7.5.1 \
                PasteDeploy==1.5.0 \
                PasteScript==1.7.3 \
                pysqlite==2.6.3 \
                Routes==1.12.3 \
                SQLAlchemy==0.6.5 \
                WebOb==0.9.8 \
"
