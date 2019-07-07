#!/bin/bash
#
# set -x

# chroot into an image either interactively -or- run a command and exit afterwards

# if a mount fails then do not try further
#
function mountall() {
  # system dirs
  #
  /bin/mount -t proc       proc        $mnt/proc   &&\
  /bin/mount --rbind       /sys        $mnt/sys    &&\
  /bin/mount --make-rslave             $mnt/sys    &&\
  /bin/mount --rbind       /dev        $mnt/dev    &&\
  /bin/mount --make-rslave             $mnt/dev    &&\
  #
  # tinderbox data dir
  #
  /bin/mount -o bind      ~tinderbox/tb     $mnt/mnt/tb           &&\
  #
  # host repo(s) et. al.
  #
  /bin/mount -o bind,ro   $repo_gentoo      $mnt/$repo_gentoo     &&\
  /bin/mount -t tmpfs     tmpfs -o size=16G $mnt/var/tmp/portage  &&\
  /bin/mount -o bind      $distfiles        $mnt/$distfiles       &&\

  if [[ -n "$repo_libressl" && -d $mnt/$repo_libressl ]]; then
    /bin/mount -o bind,ro $repo_libressl $mnt/$repo_libressl
  fi

  return $?
}


# try to umount as much as possible even if a particular umount fails
#
function umountall()  {
  local rc=0

  if [[ -n "$repo_libressl" && -d $mnt/$repo_libressl ]]; then
    /bin/umount $mnt/$repo_libressl                 || rc=$?
  fi

  /bin/umount -l $mnt/$distfiles                    || rc=$?
  /bin/umount -l $mnt/var/tmp/portage               || rc=$?
  /bin/umount    $mnt/$repo_gentoo                  || rc=$?

  /bin/umount    $mnt/mnt/tb                        || rc=$?
  /bin/umount -l $mnt/dev{/pts,/shm,/mqueue,}       || rc=$?
  /bin/umount -l $mnt/{sys,proc}                    || rc=$?

  return $rc
}


# CGroup based limitations to avoid oom-killer eg. for dev-perl/GD
# needs:
# CONFIG_MEMCG=y
# CONFIG_MEMCG_SWAP=y
# CONFIG_MEMCG_SWAP_ENABLED=y

function cgroup() {
  sysfsdir=/sys/fs/cgroup/memory/tinderbox-${mnt##*/})
  if [[ ! -d $sysfsdir ]]; then
    mkdir -p $sysfsdir
  fi

  echo "$$" > $sysfsdir/tasks

  mbytes=$(echo " 8 * 2^30" | bc)
  echo $mbytes > $sysfsdir/memory.limit_in_bytes

  vbytes=$(echo "16 * 2^30" | bc)
  echo $vbytes > $sysfsdir/memory.memsw.limit_in_bytes
}


#############################################################################
#                                                                           #
# main                                                                      #
#                                                                           #
#############################################################################

if [[ "$(whoami)" != "root" ]]; then
  echo " you must be root !"
  exit 1
fi

# the path to the chroot image
#
mnt=$1

if [[ ! -d $mnt ]]; then
  echo "not a valid mount point: '$mnt'"
  exit 1
fi

# treat remaining option(s) as command(s) to be run within chroot
#
shift

# 1st barrier to prevent starting the same chroot image twice
#
lock=$mnt/var/tmp/tb/LOCK
if [[ -f $lock ]]; then
  echo "found lock file $lock"
  exit 1
fi
touch $lock || exit 2
chown tinderbox:tinderbox $lock

# 2nd barrier to prevent starting the same chroot image twice
#
grep -m 1 "/${mnt##*/}/" /proc/mounts && exit 3

repo_gentoo=$(  portageq get_repo_path / gentoo)
repo_libressl=$(portageq get_repo_path / libressl)
distfiles=$(    portageq distdir)

mountall
if [[ $? -ne 0 ]]; then
  umountall
  exit 4
fi

cgroup

# "su - root" forces the use root's tinderbox image environment
#
if [[ $# -gt 0 ]]; then
  /usr/bin/chroot $mnt /bin/bash -l -c "su - root -c '$@'"
else
  /usr/bin/chroot $mnt /bin/bash -l -c "su - root"
fi
rc=$?

umountall
if [[ $? -ne 0 ]]; then
  exit 4
fi

rm $lock

exit $rc
