#!/bin/sh -ex

unbound-anchor -a /var/lib/unbound/root.key -r /usr/share/dns/root.hints

exec "$@"
