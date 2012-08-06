#!/bin/bash
# Script de "post installation" de GNU/Linux Mint LMDE
#
# Alexandre Aury - 07/2012
# GPL
#
# Syntaxe: # sudo ./min-12-postinstall.sh
#
# Release notes:
# 1.12.07: Premiere version du script
#
VERSION="1.12.07.1"

#=============================================================================
# Liste des applications à installer: A adapter a vos besoins
#
LISTE=""
# Developpement
LISTE=$LISTE" build-essential vim git git-core anjuta geany geany-plugins"
# Multimedia
#LISTE=$LISTE" vlc x264 ffmpeg2theora oggvideotools istanbul shotwell mplayer mppenc faac flac vorbis-tools faad lame cheese "
# Network
#LISTE=$LISTE" iperf ifstat htop netspeed nmap "
# Systeme
#LISTE=$LISTE" preload lm-sensors hardinfo  terminator conky-all"
# Web
#LISTE=$LISTE" lsb-core ttf-mscorefonts-installer mint-flashplugin chromium"

#=============================================================================

# Test que le script est lance en root
if [ $EUID -ne 0 ]; then
  echo "Le script doit être lancé en root: # sudo $0" 1>&2
  exit 1
fi

# Ajout des depots
#-----------------

MINTVERSION=`lsb_release -cs`
echo "Ajout des depots pour Linux Mint Debian Edition XFCE $MINTVERSION"

# Spotify
egrep '^deb\ .*spotify' /etc/apt/sources.list > /dev/null
if [ $? -ne 0 ]
then
	echo "## 'Spotify' repository"
	echo -e "deb http://repository.spotify.com stable non-free\n" >> /etc/apt/sources.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4E9CFF4E
fi
LISTE=$LISTE" spotify-client-qt"


# Mise a jour 
#------------

echo "Mise a jour de la liste des depots"
apt-get -y update

echo "Mise a jour du systeme"
apt-get -y upgrade

# Installations additionnelles
#-----------------------------

echo "Installation des logiciels suivants: $LISTE"

apt-get -y --force-yes install $LISTE

# XFCE
#############


# Others
########

# Conky theme
wget -O $HOME/.conkyrc https://raw.github.com/nicolargo/ubuntupostinstall/master/conkyrc

# Vimrc
wget -O - https://raw.github.com/vgod/vimrc/master/auto-install.sh | sh

# Terminator
mkdir -p ~/.config/terminator
wget -O ~/.config/terminator/config https://raw.github.com/nicolargo/ubuntupostinstall/master/config.terminator
chown -R $USERNAME:$USERNAME ~/.config/terminator

echo "========================================================================"
echo
echo "Liste des logiciels installés: $LISTE"
echo
echo "========================================================================"
echo
echo "Le script doit relancer votre session pour finaliser l'installation."
echo "Assurez-vous d’avoir fermé tous vos travaux en cours avant de continuer."
echo "Appuyer sur ENTER pour relancer votre session (ou CTRL-C pour annuler)"
read ANSWER
service lightdm restart

# Fin du script
#---------------
