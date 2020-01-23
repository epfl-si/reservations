#!/usr/bin/env bash

vhost='/var/www/vhosts/reservations.epfl.ch'

user='dinfo'
hosts='dinfo1.epfl.ch dinfo2.epfl.ch'

for h in ${hosts}; do
    ssh="ssh ${user}@${h}"
    dest="${user}@${h}"

    scp -r cgi-bin/*  ${dest}:${vhost}/cgi-bin/
    scp -r htdocs/*     ${dest}:${vhost}/htdocs/
    scp -r private/*     ${dest}:${vhost}/private/

    ${ssh} 'sudo apachectl graceful'
done