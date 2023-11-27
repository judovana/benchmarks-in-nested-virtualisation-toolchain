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

COUNTER=$1
JDK=$2
JDK_NAME=`basename ${JDK}`

#get path of folder containing JDKs from config
JDK_DIR=$(cat $SCRIPT_ORIGIN/../config | grep ^JDK_DIR= | sed "s/.*=//")

## cleaning any existing podman images and containers
podman rmi -a -f
podman rm -a -f
podman ps -all
podman images

## create local workspace
rm -rf $SCRIPT_ORIGIN/../cont_in_cont_workspace
mkdir $SCRIPT_ORIGIN/../cont_in_cont_workspace
HOST_CONT_WORKSPACE=$SCRIPT_ORIGIN/../cont_in_cont_workspace
echo finished-creating-local-workspace

## copy files necessary for benchmarking
cd $HOST_CONT_WORKSPACE
cp -r $SCRIPT_ORIGIN $HOST_CONT_WORKSPACE
cp -r /mnt/shared/TckScripts $HOST_CONT_WORKSPACE
cp -r /mnt/shared/testsuites $HOST_CONT_WORKSPACE
cp $SCRIPT_ORIGIN/../config $HOST_CONT_WORKSPACE
cp $JDK_DIR/$JDK_NAME $HOST_CONT_WORKSPACE
echo finished-copying-files-into-upcoming-container-workspace

## create the dockerfile for creating the base 
host_preparation_dockerfile=host_preparation_dockerfile
FEDORA_VERSION=$(cat $SCRIPT_ORIGIN/../config | grep ^MAINVM= | sed "s/.*=//")
FUTURE_SCRIPT=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")

echo "FROM $FEDORA_VERSION" >> $host_preparation_dockerfile

echo "RUN mkdir /local_workspace || true" >> $host_preparation_dockerfile
echo "RUN mkdir /local_workspace/local_workspace || true" >> $host_preparation_dockerfile
echo "RUN mkdir -p /home/tester/diplomka/JDKs/8 || true" >> $host_preparation_dockerfile
echo "RUN mkdir /results || true" >> $host_preparation_dockerfile

echo "COPY TckScripts /mnt/shared/TckScripts" >> $host_preparation_dockerfile
echo "COPY scripts /local_workspace/scripts" >> $host_preparation_dockerfile
#improve so only the current benchmark gets copied?
echo "COPY testsuites /mnt/shared/testsuites" >> $host_preparation_dockerfile
echo "COPY config /local_workspace" >> $host_preparation_dockerfile
echo "COPY $JDK_NAME /home/tester/diplomka/JDKs/8" >> $host_preparation_dockerfile

echo "RUN ls -l /home/tester/diplomka/JDKs/8" >> $host_preparation_dockerfile
echo "RUN ls -l /local_workspace" >> $host_preparation_dockerfile
echo "RUN ls -l /" >> $host_preparation_dockerfile
echo "RUN pwd " >> $host_preparation_dockerfile

echo 'RUN dnf -y install --disablerepo fedora-modular podman' >> $host_preparation_dockerfile

## this complicated section is needed for J2DBENCH
echo 'RUN dnf -y install --disablerepo fedora-modular wget /usr/bin/pgrep unzip bc xz /usr/bin/scp which /usr/bin/find && dnf clean all' >> $host_preparation_dockerfile
if echo ${FUTURE_SCRIPT} | grep J2DBench ; then
  if [ "x$DISPLAY" = "x" ] ; then
    echo "no DISPLAY!!!"
    export DISPLAY=:0
    #exit 11
  fi
  echo 'RUN dnf -y install --disablerepo fedora-modular xhost make fontconfig xorg-x11-fonts-Type1 libXcomposite ca-certificates javapackages-filesystem tzdata-java lksctp-tools cups-libs crypto-policies nss && dnf clean all' >> $host_preparation_dockerfile
  echo 'RUN dnf -y install --disablerepo fedora-modular adwaita-cursor-theme   adwaita-icon-theme   alsa-lib   at-spi2-atk   at-spi2-core   avahi-glib   avahi-libs   bluez-libs   bubblewrap   cairo   cairo-gobject   cdparanoia-libs   colord-libs   cpio   cups-libs   dbus   dbus-broker   dbus-common   dbus-libs   device-mapper   device-mapper-libs   exempi   exiv2-libs   fdk-aac-free   file   flac-libs   fontconfig   fonts-filesystem   freetype   fribidi   fuse   fuse-common   fuse-libs   gdk-pixbuf2   gdk-pixbuf2-modules   geoclue2   gettext   gettext-libs   giflib   glib-networking   gobject-introspection   google-noto-fonts-common   google-noto-sans-vf-fonts   graphene   graphite2   gsettings-desktop-schemas   gsm   gstreamer1   gstreamer1-plugins-base   gtk-update-icon-cache   harfbuzz   hicolor-icon-theme   hwdata   iso-codes   jbigkit-libs   json-glib   kbd   kbd-misc   lame-libs   langpacks-core-font-en   lcms2   libX11   libX11-common   libX11-xcb   libXau   libXcomposite   libXcursor   libXdamage   libXext   libXfixes   libXft   libXi   libXinerama   libXrandr   libXrender   libXtst   libXv   libXxf86vm   libappstream-glib   libargon2   libasyncns   libatomic   libcanberra   libcanberra-gtk3   libcbor   libcloudproviders   libcue   libdatrie   libdrm   libedit   libepoxy   libexif   libfdisk   libfontenc   libgexiv2   libglvnd   libglvnd-egl   libglvnd-glx   libgrss   libgsf   libgudev   libgusb   libgxps   libicu   libiptcdata   libjpeg-turbo   libkcapi   libkcapi-hmaccalc   libldac   libmysofa   libnotify   libogg   libosinfo   libpciaccess   libpng   libproxy   librsvg2   libsbc   libseccomp   libsndfile   libsoup   libstemmer   libtdb   libthai   libtheora   libtiff   libtool-ltdl   libtracker-sparql   libunwind   libusb1   libutempter   libvisual   libvorbis   libwayland-client   libwayland-cursor   libwayland-egl   libwayland-server   libwebp   libxcb   libxkbcommon   libxshmfence   libxslt   lilv-libs   lksctp-tools   llvm-libs   low-memory-monitor   malcontent-libs   mesa-libEGL   mesa-libGL   mesa-libgbm   mesa-libglapi   mesa-vulkan-drivers   mkfontscale   mozjs91   mpg123-libs   nspr   nss   nss-softokn   nss-softokn-freebl   nss-sysinit   nss-util   openjpeg2   opus   orc   os-prober   osinfo-db   osinfo-db-tools   ostree-libs   pango   pixman   polkit   polkit-libs   polkit-pkla-compat   poppler   poppler-data   poppler-glib   procps-ng   pulseaudio-libs   pulseaudio-utils   rtkit   serd   sord   sratom   systemd   systemd-pam   systemd-udev   totem-pl-parser   tracker   ttmkfdir   tzdata-java   uchardet   upower   util-linux   vulkan-loader   webkit2gtk3-jsc   webrtc-audio-processing   which   wireplumber   wireplumber-libs   xdg-dbus-proxy   xdg-desktop-portal   xkeyboard-config   xml-common   xorg-x11-fonts-Type1   xz         && dnf clean all' >> $host_preparation_dockerfile
  echo "RUN mkdir /mnt/ramdisk " >> $host_preparation_dockerfile #jtreg prep seems to b needing this
fi

echo finished-creating-host-prep-dockerfile

## this complicated section is needed for J2DBENCH
SCRIPT=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")
GUI_PART=""
if echo ${SCRIPT} | grep J2DBench ; then
  if [ "x$DISPLAY" = "x" ] ; then
    echo "no DISPLAY!!!"
    export DISPLAY=:0
    #exit 12
  fi
  echo "DISPLAY=$DISPLAY"
  xhost +"local:podman@" #<- normal user !!! mandatory
  GUI_PART="-v /tmp/.X11-unix:/tmp/.X11-unix:ro -e \"DISPLAY\" --security-opt label=type:container_runtime_t "
fi

podman build --tag host-preparation-cont -f ./$host_preparation_dockerfile

podman run $GUI_PART --privileged --name prepared-base-cont-with-jdk host-preparation-cont sh /local_workspace/scripts/create_container_on_container_or_VM.sh $COUNTER $JDK False


