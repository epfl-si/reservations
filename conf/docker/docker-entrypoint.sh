#!/usr/bin/env bash
###############################################################
# Get tequila certificate fingerprint
###############################################################
export TEQUILA_FINGERPRINT=`openssl s_client -connect $TEQUILA_HOST:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin | sed "s/ Fingerprint=/$/g" | sed "s/SHA1/sha1/g"`

###############################################################
# Substitute env vars in config files
###############################################################
envsubst < "/home/dinfo/dbs.conf" > "/tmp/dbs.conf"
cat /tmp/dbs.conf > /opt/dinfo/etc/dbs.conf
envsubst < "/home/dinfo/tequila.conf" > "/tmp/tequila.conf"
cat /tmp/tequila.conf > /etc/tequila.conf
envsubst < "/home/dinfo/25-reservations.epfl.ch.conf" > "/tmp/apache.conf"
cat /tmp/apache.conf > /etc/apache2/sites-available/25-reservations.epfl.ch.conf
# Cannot use envsubst for access_params, because it contains $xxxx strings which must not be replaced
cp /home/dinfo/access_params /tmp/access_params
sed -i 's/RC4_KEY/'"$RC4_KEY"'/g' /tmp/access_params
sed -i 's/AES_KEY/'"$AES_KEY"'/g' /tmp/access_params
cat /tmp/access_params > /var/www/vhosts/reservations.epfl.ch/private/etc/access_params

sudo rm -f /var/run/apache2/apache2.pid && sudo /usr/sbin/apachectl -e debug -D FOREGROUND -k restart