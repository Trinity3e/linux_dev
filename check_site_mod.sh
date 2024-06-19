#!/bin/bash

for pid in $(pgrep "${BASH_SOURCE:-$0}"); do
if [ "$pid" != $$ ]; then
echo "[$(date)] : $0 : Process is already running with PID $pid"
exit 1
fi
done


input="/home/opc/scripts/clients"

path="/home/opc/scripts"

sites_folder="sites"


fetch() { status=$(curl --retry 2 --retry-delay 3 -A 'Mozilla/5.0' -s -o "$path/$sites_folder/$CLIENT/$CLIENT" --write-out "%{http_code}" "https://$CLIENT" 2>/dev/null); }
testdown() { [[ -z $status ]] || [[ $status -gt 400 ]] || [[ $status -lt 100 ]] && ( echo -e "Notificare CLIENT=$CLIENT - site down!!!" | mail -s "Site căzut!" daniel.cristea@winsys.ro ); }


while IFS= read -r line
do

CLIENT=$(cut -d: -f1 <<<"$line")

#echo -e "CLIENT=$CLIENT"

mkdir -p "$path/$sites_folder/$CLIENT"

if [ -f "$path/$sites_folder/$CLIENT/$CLIENT" ]; then

cp "$path/$sites_folder/$CLIENT/$CLIENT" "$path/$sites_folder/$CLIENT/$CLIENT.old"

fetch

I=$(wc -c "$path/$sites_folder/$CLIENT/$CLIENT.old" | cut -d' ' -f1)
J=$(wc -c "$path/$sites_folder/$CLIENT/$CLIENT" | cut -d' ' -f1)

[[ $I -ne $J ]] && ( echo -e "Notificare CLIENT=$CLIENT - site changed!!!" | mail -s "Verifică site!" daniel.cristea@winsys.ro )
testdown

else

fetch
testdown

fi

done < $input

