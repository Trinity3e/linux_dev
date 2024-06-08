#! /bin/bash
while [[ -f hosts.txt ]]; do cat hosts.txt | while read -r h; do
status=$(curl --retry 2 --retry-delay 3 -s -L --output /tmp/title --write-out "%{http_code}" "$h" | head -n1 | tr -dc '0-9')
[[ $status -gt 400 ]] && status=$(curl --retry 2 --retry-delay 3 -A 'Mozilla/5.0' -s -L --output /tmp/title --write-out "%{http_code}" "$h" | head -n1 | tr -dc '0-9')
shortlink=$(tail -c20 <<<"$h")
if [[ $status -lt 400 ]] && [[ $status -gt 100 ]]; then
echo -ne "\n$shortlink UP [$status]"; if [ "$1" = "title" ]; then sed -n -e 's!.*<title>\(.*\)</title>.*!\1!p' /tmp/title | sed 's/^.*$/ [ title: & ]/g'; strings /tmp/title | head -n1 | grep -vi 'html' | head -c25 | sed 's/^.*$/ [ content: & ]/g'; fi | tr -d '\n'; else
text="\n$shortlink DOWN $([[ -n $status ]] && ! [ "$status" = '000' ] && echo [$status])"; echo -ne "$text"; echo -ne "$text" >> /tmp/errh; ! diff -q <(tail -n1 /tmp/errh) <(echo -ne "$text") >/dev/null && mail -s "$(tr '[!@#$%^&*({})|+]' ' ' <<<$shortlink) down" mail@mail.xyz <<<"$text"; fi
done; sleep 5; clear; done
