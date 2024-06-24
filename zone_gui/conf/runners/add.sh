#!/bin/sh

ipv4_validate() {
grep -oqE '((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])(/[1-3][0-9]|\s|$)'
}

ipv6_validate() {
grep -oqE '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(/[1-3][0-9]{1,2}|\s|$)'
}

link=$1
! ipv4_validate <<<$2 && echo Invalid IP address && exit 1

zonefile="
\$TTL    604800
@       IN      SOA     ns1.cgii.ro. (
                  3     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
; name servers - NS records
     IN      NS      ns1.cgii.ro.
     IN      NS      ns2.cgii.ro.
     IN      NS      ns3.cgii.ro.

; name servers - A records
ns1.cgii.ro.          IN      A       150.230.151.113
ns2.cgii.ro.          IN      A       144.24.183.194
ns3.cgii.ro           IN      A       138.2.138.5

www.$link.            IN      A      $2
$link.                IN      A      $2"

ipv4_validate <<<$3 && zonefile+="
www.$link.            IN      A      $3
$link.                IN      A      $3"

ipv6_validate <<<$4 && zonefile+="
www.$link.            IN      AAAA      $4
$link.                IN      AAAA      $4"

mastercfg="
zone \"$link\" {
    type master;
    file \"$link.zone\";
    allow-transfer { 144.24.183.194; 138.2.138.5; };
};
"

slavecfg="
zone \"$link\" {
    type slave;
    file \"$link.zone\";
    masters { 150.230.151.113; };
};
"

echo "
zone file:
###########################


$zonefile


###########################

master:

$mastercfg

slave:

$slavecfg
"

echo "$zonefile" > /tmp/"$link".zone
echo "$mastercfg" > /tmp/zonetoadd_ma
echo "$slavecfg"  > /tmp/zonetoadd_sl

echo -n "put /tmp/zonetoadd_ma" | sftp -i $HOME/ns1.key opc@ns1.cgii.ro:/tmp
ssh -i $HOME/ns1.key opc@ns1.cgii.ro -t 'sh -c "cat /tmp/zonetoadd_ma | sudo tee -a /etc/named.conf && rm /tmp/zonetoadd_ma"' 2>/dev/null
echo -n "put /tmp/"$link".zone" | sftp -i $HOME/ns1.key opc@ns1.cgii.ro:/tmp
ssh -i $HOME/ns1.key opc@ns1.cgii.ro -t 'sh -c "sudo mv -vf /tmp/*.zone /var/named; sudo systemctl restart named"' 2>/dev/null


echo -n "put /tmp/zonetoadd_sl" | sftp -i $HOME/ns2.key opc@ns2.cgii.ro:/tmp
ssh -i $HOME/ns2.key opc@ns2.cgii.ro -t 'sh -c "cat /tmp/zonetoadd_sl | sudo tee -a /etc/named.conf && rm /tmp/zonetoadd_sl"' 2>/dev/null
echo -n "put /tmp/"$link".zone" | sftp -i $HOME/ns2.key opc@ns2.cgii.ro:/tmp
ssh -i $HOME/ns2.key opc@ns2.cgii.ro -t 'sh -c "sudo mv -vf /tmp/*.zone /var/named; sudo systemctl restart named"' 2>/dev/null

