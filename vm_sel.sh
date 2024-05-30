#! /bin/bash

#V1.3

runningasroot() { [[ $(whoami 2>/dev/null || echo $USER) = root ]]; }
testcmd() { command -v $1 >/dev/null 2>&1; }
tex() { [[ $tr = 1 ]] && return 1; testcmd $1 && tr=1; tmtxt=Demo; }

tex alacritty && term="$_ -t $tmtxt -e"; tex kgx && term="$_ -T $tmtxt -e"; tex kitty && term="$_ -T $tmtxt"; tex konsole && term="$_ -p tabtitle=$tmtxt --nofork -e"
tex lxterminal && term="$_ -t $tmtxt -e"; tex qterminal && term="$_ -e"; tex terminator && term="$_ -T $tmtxt -x"; tex tilix && term="$_ -t $tmtxt -e"; tex xfce4-terminal && term="$_ -T $tmtxt -x"


sel() {
selopt=0 elnr=$(( ${#menu[@]} - 1 )) color1='45;140;155' color2='245;220;50' ttl_text=" $title "; while true; do cols=$(tput cols)
# prepare text feed, output title and header
echo -e '\e[1K\e[H\e[?7h\e[J\e[?25l\e[1m\e[48;2;'$color1'm'"$(printf %"$cols"s)"'\e['$(( $cols - 10 ))'G'"$(date '+%a %R')"'\e[49m\e['$(( ( $cols - ${#ttl_text} ) / 2 ))'G'$ttl_text'\e[38;2;'$color1'm\e[1E\e[2K'$header'\e[0m\e[K'
# output the options
seq 0 "$elnr" | while read i; do [ "$i" = "$selopt" ] && bef='\e[1;38;2;'$color2';48;2;'$color1'm' aft='\e[0m' || unset bef aft; echo -e "\e[1K$bef${menu[$i]}$aft\e[K"; done
# make the selection
read -s -n3 key
case $key in
	$'\x1b[B') [ $selopt -ne $elnr ] && let selopt=selopt+1;; # up
	$'\x1b[A') [ $selopt -ne 0 ] && let selopt=selopt-1;; # down
	""|$'\x1b[C') opt="${menu["$selopt"]}"; echo -e "\e[H\e[J\e[?25h"; return 0;; # select (Enter/right)
	*) break
esac; done
}

dir='/var/lib/libvirt/images'
getname() { name=$(basename -s '.qcow2' $f | sed 's/ /_/g'); }
start_vm() {
cd /tmp
#n=0; find "$dir" -type f -name '*.qcow2' | while read -r f; do let n=n+1; getname; qemu-system-x86_64 -drive file="$f" -m 8G -cpu host -enable-kvm -smp 4 -monitor unix:$name,server,nowait -spice port=333$n,disable-ticketing=on -daemonize; done; sleep 5 # backend fara libvirt
for i in $(virsh list --name --inactive | grep -E [a-z]); do virsh start "$i"; done
}
loop_vm() {
touch /tmp/lplock; while ps aux | grep -q [X]vnc && [[ -f /tmp/lplock ]]; do
#find "$dir" -type f -name '*.qcow2' | while read -r f; do getname; echo info spice | socat - unix-connect:$name | awk -F':' '/address/ {if (int($3) < 3400) print int($3)}'; done | # backend fara libvirt
virsh list --name | grep desktop | while read -r i; do pgrep -a qemu | grep $i | grep -oE '\-spice port=[0-9]{4}' | tr -dc '0-9\n'; done |
while read -r i; do timeout 15 sudo -u winsys --preserve-env=DISPLAY nohup remote-viewer -f spice://localhost:$i >/dev/null; ! [ $? = 124 ] && rm /tmp/lplock && break; done; done # exit manual pe alt semnal decat cel de timeout 124 intrerupe bucla
}

if [[ $1 = '-loop' ]]; then start_vm; loop_vm; else

if [ -t 0 ]; then

while true; do
title='VM menu' header="qemu instances: $(pgrep qemu | wc -l)"
mapfile -t menu <<<"$(
# find "$dir" -type f -name '*.qcow2' | while read -r f; do getname; echo info spice | socat - unix-connect:$name | awk -F':' '/address/ {if (int($3) < 3400) print " -> view '$name' on port "int($3)}'; done # backend fara libvirt
virsh list --name | grep -E [a-z] | while read -r i; do echo " -> view $i on port $(pgrep -a qemu | grep $i | grep -oE '\-spice port=[0-9]{4}' | tr -dc '0-9')"; done

echo -e " -> start all $(
# ls $dir | grep -oc qcow2 # backend fara libvirt
virsh list --name --inactive | grep -E [a-z] | wc -l

) from $dir\n -> Begin loop\n -> Exit")"
sel
case $opt in
*\ start*)
start_vm
;;
*\ view*)
sudo -u winsys --preserve-env=DISPLAY nohup remote-viewer spice://localhost:$(cut -d' ' -f7 <<<$opt) -t $(cut -d' ' -f4 <<<$opt) >/dev/null & disown
;;
*\ Begin*)
loop_vm
;;
*)
exit
esac
done

else
$term sh -c "$(realpath ${BASH_SOURCE:-$0})"

fi; fi
