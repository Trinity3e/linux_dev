#!/bin/bash

if [[ -z $1 ]]; then
ssh -i $HOME/ns1.key opc@ns1.cgii.ro -t "sh -c 'sudo find /var/named -name '*.zone' | xargs basename -s .zone'" 2>/dev/null
#grep -o 'file.*\.zone' /etc/named.conf | cut -d'"' -f2 | sed 's/.zone//g'

else
ssh -i $HOME/ns2.cgii.ro.key opc@ns2.cgii.ro -t "sh -c '
! sudo grep '$1' /etc/named.conf && echo No such domain && exit 1
echo sed -ie '/$1/,+5d' /etc/named.conf &&
echo rm -vf /var/named/'$1'.zone &&
echo Zone '$1' removed
sudo systemctl restart named
sudo systemctl status named
'"
fi
