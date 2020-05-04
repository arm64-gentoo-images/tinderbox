#!/bin/bash
#
# set -x

export LANG=C.utf8
export GREP_COLOR="never"
export GREP_COLORS="never"

# check if stdout/err of job.sh was made
#

mailto="tinderbox@zwiebeltoralf.de"

f=/tmp/${0##*/}.out

while :
do
  if [[ ! -f $f ]]; then
    if [[ -n "$(ls ~/logs/)" ]]; then
      if [[ "$(wc -c ~/logs/* 2>/dev/null | tail -n 1 | awk ' { print $1 } ')" != "0" ]]; then
        (
          ls -l ~/logs/*
          echo
          head -v ~/logs/*
          echo
          ls -l ~/run/*/var/tmp/tb/mail.log
          echo
          head -v ~/run/*/var/tmp/tb/mail.log

          echo -e "\nto re-activate this test again, do:\n\n   tail -v ~/logs/*; truncate -s 0 ~/logs/*; rm -f $f\n"
        ) >> $f

        cat $f | mail -s "logs are non-empty" $mailto
      fi
    fi
  fi

  sleep 5
done
