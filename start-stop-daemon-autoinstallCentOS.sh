#!/bin/bash
#
# Script to install start-stop-daemon on CentOS 6
# 
# Alexandre Aury - 08/2012
# LGPL
#
# 
#
##############################

# Variables globales
#-------------------

YUM_EXEC="yum -q -y"
WGET="wget --no-check-certificate"
DATE=`date +"%Y%m%d%H%M%S"`
LOG_FILE="/tmp/nginxautoinstall-$DATE.log"

# Functions
#-----------------------------------------------------------------------------

displaymessage() {
  echo "$*"
}

displaytitle() {
  displaymessage "------------------------------------------------------------------------------"
  displaymessage "$*"  
  displaymessage "------------------------------------------------------------------------------"

}

displayerror() {
  displaymessage "$*" >&2
}

# First parameter: ERROR CODE
# Second parameter: MESSAGE
displayerrorandexit() {
  local exitcode=$1
  shift
  displayerror "$*"
  exit $exitcode
}

# First parameter: MESSAGE
# Others parameters: COMMAND (! not |)
displayandexec() {
  local message=$1
  echo -n "[En cours] $message"
  shift
  echo ">>> $*" >> $LOG_FILE 2>&1
  sh -c "$*" >> $LOG_FILE 2>&1
  local ret=$?
  if [ $ret -ne 0 ]; then
    echo -e "\r\e[0;31m   [ERROR]\e[0m $message $ret"
  else
    echo -e "\r\e[0;32m      [OK]\e[0m $message"
  fi
  return $ret
}

# Debut de l'installation
#-----------------------------------------------------------------------------

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit √™tre lanc√© en root (droits administrateur)" 1>&2
  exit 1
fi

displaytitle "Install prerequisites"
# Ouverture du dossiers d'installation
cd /usr/local/src

displayandexec "Téléchargement de dpkg v1.15.8.4" wget -c "http://za.archive.ubuntu.com/ubuntu/pool/main/d/dpkg/dpkg_1.15.8.4ubuntu3.tar.bz2"

displayandexec "Décompression" tar jfxvh dpkg_1.15.8.4ubuntu3.tar.bz2
displayandexec "Suppression de l'archive" rm dpkg_1.15.8.4ubuntu3.tar.bz2
cd dpkg-1.15.8.4ubuntu2/
displayandexec "Configuration" ./configure --without-install-info --without-update-alternatives --without-dselect
displayandexec "Installation" make && make install


# Summary
echo ""
echo "------------------------------------------------------------------------------"
echo "                    dpkg ubuntu installation finished"
echo "------------------------------------------------------------------------------"
echo ""
echo "Installation & configuration folder:       /usr/local/src/dpkg-1.15.8.4ubuntu2/"
echo ""
echo "------------------------------------------------------------------------------"
echo ""

# Fin du script
