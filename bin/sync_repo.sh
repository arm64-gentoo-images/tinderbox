#!/bin/bash
#
#set -x

set -uf

export PATH="/usr/sbin:/usr/bin:/sbin:/bin:/opt/tb/bin"
export LANG=C.utf8

if [[ "$(whoami)" != "root" ]]; then
  echo " you must be root"
  exit 1
fi

mailto="tor-relay@zwiebeltoralf.de"

log="/tmp/${0##*/}.log"

date > "$log" || exit 1
eix-sync &>> $log
rc1=$?

# musl repo is not configured at the tinderbox host so eix-sync can't care for it
#
date >> $log
cd /var/db/repos/musl/ && git pull &>> $log
rc2=$?

if [[ $rc1 -ne 0 || $rc2 -ne 0 || -n "$(grep 'git pull error' $log)" ]]; then
  mail -s "${0##*/}: return codes: eix=$rc1 musl=$rc2" $mailto < $log
  exit 1
fi

# timestamp can't be queried within an image b/c git isn't part of stage3 and might not yet be installed
#
for repo in gentoo libressl musl
do
  cd /var/db/repos/$repo && git show -s --format="%ct" HEAD > timestamp.git
done

echo  >> $log
date  >> $log

grep -q "warning: There are too many unreachable loose objects; run 'git prune' to remove them." $log
if [[ $? -eq 0 ]]; then
  for repo in gentoo libressl musl
  do
    cd /var/db/repos/$repo && git prune &>> $log
  done
fi

