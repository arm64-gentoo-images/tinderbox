#!/bin/sh
#
# set -x

# this is a (s)imple (c)hroot (w)rapper into a (running) tinderbox image

mnt=$1

# remaining options are treated as a complete command line to be run within chroot
#
shift

if [[ $# -gt 0 ]]; then
  # do "su - root" to double ensure to use the chroot image environment
  #
  /usr/bin/chroot $mnt /bin/bash -l -c "su - root -c '$@'"
else
  /usr/bin/chroot $mnt /bin/bash -l
fi

exit $?
