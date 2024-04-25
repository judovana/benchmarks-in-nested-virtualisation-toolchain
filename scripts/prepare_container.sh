#!/bin/bash

## resolve folder of this script, following all symlinks,
## http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
readonly SCRIPT_ORIGIN="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
	readonly REPO_DIR=`dirname $SCRIPT_ORIGIN`
readonly REPO_NAME=`basename $REPO_DIR`

set -exo pipefail

IS_NESTED=$1
## cleaning any existing podman images and containers
podman rmi -a -f
podman rm -a -f
podman ps -all
podman images

## create local workspace
rm -rf $SCRIPT_ORIGIN/../local_workspace
mkdir $SCRIPT_ORIGIN/../local_workspace
CONT_WORKSPACE=$SCRIPT_ORIGIN/../local_workspace

## copy files necessary for benchmarking
cd $CONT_WORKSPACE
cp -r $SCRIPT_ORIGIN $CONT_WORKSPACE
cp -r /mnt/shared/TckScripts $CONT_WORKSPACE
cp -r /mnt/shared/testsuites $CONT_WORKSPACE

if [ $IS_NESTED == True ]; then
  FEDORA_VERSION=$(cat $SCRIPT_ORIGIN/../config | grep ^NESTED= | sed "s/.*=//")
else
  FEDORA_VERSION=$(cat $SCRIPT_ORIGIN/../config | grep ^MAINVM= | sed "s/.*=//")
fi

## get which benchmark is going to be run
FUTURE_SCRIPT=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")

## create the dockerfile for creating the base 
preparation_dockerfile=preparation_dockerfile
echo "FROM $FEDORA_VERSION" >> $preparation_dockerfile
echo 'RUN dnf -y install --disablerepo fedora-modular wget /usr/bin/pgrep unzip bc xz /usr/bin/scp which /usr/bin/find && dnf clean all' >> $preparation_dockerfile

## this part is necessary to make J2DBench GUI part work on container
if echo ${FUTURE_SCRIPT} | grep J2DBench ; then
  if [ "x$DISPLAY" = "x" ] ; then
    echo "no DISPLAY!!!"
    export DISPLAY=:0
    #exit 11
  fi
  echo 'RUN dnf -y install --disablerepo fedora-modular  xhost make fontconfig xorg-x11-fonts-Type1 libXcomposite ca-certificates javapackages-filesystem tzdata-java lksctp-tools cups-libs crypto-policies nss && dnf clean all' >> $preparation_dockerfile
  echo 'RUN dnf -y install --disablerepo fedora-modular  adwaita-cursor-theme   adwaita-icon-theme   alsa-lib   at-spi2-atk   at-spi2-core   avahi-glib   avahi-libs   bluez-libs   bubblewrap   cairo   cairo-gobject   cdparanoia-libs   colord-libs   cpio   cups-libs   dbus   dbus-broker   dbus-common   dbus-libs   device-mapper   device-mapper-libs   exempi   exiv2-libs   fdk-aac-free   file   flac-libs   fontconfig   fonts-filesystem   freetype   fribidi   fuse   fuse-common   fuse-libs   gdk-pixbuf2   gdk-pixbuf2-modules   geoclue2   gettext   gettext-libs   giflib   glib-networking   gobject-introspection   google-noto-fonts-common   google-noto-sans-vf-fonts   graphene   graphite2   gsettings-desktop-schemas   gsm   gstreamer1   gstreamer1-plugins-base   gtk-update-icon-cache   harfbuzz   hicolor-icon-theme   hwdata   iso-codes   jbigkit-libs   json-glib   kbd   kbd-misc   lame-libs   langpacks-core-font-en   lcms2   libX11   libX11-common   libX11-xcb   libXau   libXcomposite   libXcursor   libXdamage   libXext   libXfixes   libXft   libXi   libXinerama   libXrandr   libXrender   libXtst   libXv   libXxf86vm   libappstream-glib   libargon2   libasyncns   libatomic   libcanberra   libcanberra-gtk3   libcbor   libcloudproviders   libcue   libdatrie   libdrm   libedit   libepoxy   libexif   libfdisk   libfontenc   libgexiv2   libglvnd   libglvnd-egl   libglvnd-glx   libgrss   libgsf   libgudev   libgusb   libgxps   libicu   libiptcdata   libjpeg-turbo   libkcapi   libkcapi-hmaccalc   libldac   libmysofa   libnotify   libogg   libosinfo   libpciaccess   libpng   libproxy   librsvg2   libsbc   libseccomp   libsndfile   libsoup   libstemmer   libtdb   libthai   libtheora   libtiff   libtool-ltdl   libtracker-sparql   libunwind   libusb1   libutempter   libvisual   libvorbis   libwayland-client   libwayland-cursor   libwayland-egl   libwayland-server   libwebp   libxcb   libxkbcommon   libxshmfence   libxslt   lilv-libs   lksctp-tools   llvm-libs   low-memory-monitor   malcontent-libs   mesa-libEGL   mesa-libGL   mesa-libgbm   mesa-libglapi   mesa-vulkan-drivers   mkfontscale   mozjs91   mpg123-libs   nspr   nss   nss-softokn   nss-softokn-freebl   nss-sysinit   nss-util   openjpeg2   opus   orc   os-prober   osinfo-db   osinfo-db-tools   ostree-libs   pango   pixman   polkit   polkit-libs   polkit-pkla-compat   poppler   poppler-data   poppler-glib   procps-ng   pulseaudio-libs   pulseaudio-utils   rtkit   serd   sord   sratom   systemd   systemd-pam   systemd-udev   totem-pl-parser   tracker   ttmkfdir   tzdata-java   uchardet   upower   util-linux   vulkan-loader   webkit2gtk3-jsc   webrtc-audio-processing   which   wireplumber   wireplumber-libs   xdg-dbus-proxy   xdg-desktop-portal   xkeyboard-config   xml-common   xorg-x11-fonts-Type1   xz         && dnf clean all' >> $preparation_dockerfile
  echo "RUN mkdir /mnt/ramdisk " >> $preparation_dockerfile #jtreg prep seems to be needing this
fi

echo "RUN mkdir /test || true" >> $preparation_dockerfile
echo 'RUN mkdir /test/scripts || true' >> $preparation_dockerfile
echo "RUN mkdir /mnt/shared || true" >> $preparation_dockerfile
echo "RUN mkdir /mnt/shared/testsuites || true" >> $preparation_dockerfile
echo "RUN mkdir /mnt/shared/TckScripts || true" >> $preparation_dockerfile
echo "RUN mkdir /results || true" >> $preparation_dockerfile

echo "COPY TckScripts /mnt/shared/TckScripts" >> $preparation_dockerfile
echo "COPY scripts /test/scripts" >> $preparation_dockerfile
#improve so only the current benchmark gets copied?
echo "COPY testsuites /mnt/shared/testsuites" >> $preparation_dockerfile

echo "RUN ls -l /mnt/shared/testsuites" >> $preparation_dockerfile
echo "RUN ls -l /" >> $preparation_dockerfile
echo "RUN pwd " >> $preparation_dockerfile

podman build --tag preparation-cont -f ./$preparation_dockerfile 

echo finished-preparing-container

