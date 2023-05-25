#!/usr/bin/env bash
###############################################################
# Get tequila certificate fingerprint
###############################################################
export TEQUILA_FINGERPRINT=`openssl s_client -connect $TEQUILA_HOST:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin | sed "s/ Fingerprint=/$/g" | sed "s/SHA1/sha1/g"`

# Dispatch config files from configmap folder
[ -f "/opt/dinfo/etc/tnsnames.ora" ] && cp "/opt/dinfo/etc/tnsnames.ora" /etc/tnsnames.ora
[ -f "/opt/dinfo/etc/access_params" ] && cp "/opt/dinfo/etc/access_params" /var/www/vhosts/reservations.epfl.ch/private/etc/access_params

apachectl -e debug -D FOREGROUND
