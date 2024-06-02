#!/bin/bash

if [[ -z $1 ]]; then
#ssh -t'' blabla
grep -o 'file.*\.zone' /etc/named.conf | cut -d'"' -f2 | sed 's/.zone//g'

else
#ssh -t'' blabla
! grep -q "$1" /etc/named.conf && echo No such domain && exit 1
echo "To be removed: $1
sed -ie "/$1/,+5d" /etc/named.conf
rm -v /var/named/"$1".zone"
fi
