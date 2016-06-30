# tinderbox
The goal is to detect build issues of and conflicts between Gentoo Linux packages.

## scripts
The setup of an image is made by *tbs.sh*. An image is started with *start_img.sh* and stopped with *stop_img.sh*. Bugs are filed with *bgo.sh*. Install artefacts are detected by *PRE-CHECK.sh* script. Latest ebuilds are put on top of arbitrarily choosen package lists by *insert_pkgs.sh*.
The ehlper script *chr.sh* is used to bind-mount host directories onto their chroot mount point counterparts. The wrapper *runme.sh* supports a smooth upgrade of the tinderbox script *job.sh* itself.

## data files
The data files shared to all images. There're portage files *package.{accept_keywords,env,mask,unmask,use}.common* and files to *CATCH_ISSUES* or to *IGNORE_ISSUES*. *ALREADY_CATCHED* helps to avoid filing more than one bug for the same package. *IGNORE_PACKAGES* contains atoms which should not be emerged explicitely. If an error listed in *FATAL_ISSUES* would occurr then the tinderbox script stops.

## installation
Copy both *bin* and *data* into */home/tinderbox/tb*, create a (big) directory to hold the chroot images, maybe adapt the shell variable *$tbhome* and start your own tinderbox.

## typical calls
Setup a new image:

    $> echo "sudo ~/tb/bin/tbs.sh -A -m unstable -i ~/images2 -p default/linux/amd64/13.0/desktop/kde" | at now

Start all not-running images:

    $> ~/tb/bin/start_img.sh


## more info
Have a look at https://www.zwiebeltoralf.de/tinderbox.html too.

