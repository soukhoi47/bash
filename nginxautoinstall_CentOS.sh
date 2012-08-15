#!/bin/bash
#
# My own script to install/upgrade NGinx+PHP5_FPM+MemCached from sources on CentOS
# Mon script d'installation/maj de NGinx+PHP5_FPM+MemCached depuis les sources sur CentOS
# 
# Alexandre Aury - 08/2012
# LGPL
#
# Syntaxe: # su - -c "./nginxautoinstall.sh"
# 
#
VERSION="1.01"

##############################
# Version de NGinx a installer

NGINX_VERSION="1.3.3"   # The dev version
#NGINX_VERSION="1.2.2"   # The stable version

###############################
# Liste des modules a installer

NGINX_MODULES=" --with-http_dav_module --http-client-body-temp-path=/var/lib/nginx/body --with-http_ssl_module --http-proxy-temp-path=/var/lib/nginx/proxy --with-http_stub_status_module --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --with-debug --with-http_flv_module --with-http_realip_module --with-http_mp4_module"

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

# Instalation des dépendances
displayandexec "Ajout du depot EPEL" "rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm"
displayandexec "Ajout du depot REMI" "rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm"
# MaJ des depots
displayandexec "Update the repositories list" $YUM_EXEC update

# Pre-requis
displayandexec "Install development tools" $YUM_EXEC install redhat-lsb
displayandexec "Install development tools" $YUM_EXEC install pcre-devel zlib-devel openssl-devel
displayandexec "Install PHP 5" $YUM_EXEC --enablerepo=remi install php-cli php-common php-mysql php-suhosin php-fpm php-pear php-pecl-apc php-gd php-curl
displayandexec "Install MemCached" $YUM_EXEC install  php-pecl-memcached php-pecl-memcache memcached
#libcache-memcached-perl
#displayandexec "Install Redis" $YUM_EXEC --enablerepo=epel install redis-server
#displayandexec "Download PHP-Redis" git clone https://github.com/nicolasff/phpredis.git
#displayandexec "Install PHP-Redis" cd phpredis
#	git clone https://github.com/nicolasff/phpredis.git
#	phpize
#	./configure
#	make
#	make install
#
#	cd /etc/php.d 
#	sortie='redis.ini'
#	echo 'extension=redis.so' > $sortie
	
	
displaytitle "Install NGinx version $NGINX_VERSION"

# Telechargement des fichiers
displayandexec "Download NGinx version $NGINX_VERSION" $WGET http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz

# Extract
displayandexec "Uncompress NGinx version $NGINX_VERSION" tar zxvf nginx-$NGINX_VERSION.tar.gz

# Configure
cd nginx-$NGINX_VERSION
displayandexec "Configure NGinx version $NGINX_VERSION" ./configure --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --http-log-path=/var/log/nginx/access.log $NGINX_MODULES

# Compile
displayandexec "Compile NGinx version $NGINX_VERSION" make

# Install or Upgrade
TAGINSTALL=0
if [ -x /usr/local/nginx/sbin/nginx ]
then
	# Upgrade
	cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.$DATE
	displayandexec "Upgrade NGinx to version $NGINX_VERSION" make install

else
	# Install
	displayandexec "Install NGinx version $NGINX_VERSION" make install
	TAGINSTALL=1
fi

# Post installation
if [ $TAGINSTALL == 1 ]
then
	displayandexec "Post installation script for NGinx version $NGINX_VERSION" "cd .. ; mkdir /var/lib/nginx ; mkdir /etc/nginx/conf.d ; mkdir /etc/nginx/sites-enabled ; mkdir /var/www ; chown -R www-data:www-data /var/www"
fi

# Download the default configuration file
# Nginx + default site
if [ $TAGINSTALL == 1 ]
then
	displayandexec "Init the default configuration file for NGinx" "$WGET https://raw.github.com/nicolargo/debianpostinstall/master/nginx.conf ; $WGET https://raw.github.com/nicolargo/debianpostinstall/master/default-site ; mv nginx.conf /etc/nginx/ ; mv default-site /etc/nginx/sites-enabled/"
fi

# Download the init script
displayandexec "Install the NGinx init script" "$WGET https://raw.github.com/nicolargo/debianpostinstall/master/nginx ; mv nginx /etc/init.d/ ; chmod 755 /etc/init.d/nginx ; /usr/sbin/update-rc.d -f nginx defaults"

# Log file rotate
cat > /etc/logrotate.d/nginx <<EOF
/var/log/nginx/*_log {
	missingok
	notifempty
	sharedscripts
	postrotate
		/bin/kill -USR1 \`cat /var/run/nginx.pid 2>/dev/null\` 2>/dev/null || true
	endscript
}
EOF

displaytitle "Start processes"

# Start PHP5-FPM and NGinx
if [ $TAGINSTALL == 1 ]
then
	displayandexec "Start PHP 5" /etc/init.d/php-fpm start
	displayandexec "Start NGinx" /etc/init.d/nginx start
else
	displayandexec "Restart PHP 5" /etc/init.d/php-fpm restart
	displayandexec "Restart NGinx" "killall nginx ; /etc/init.d/nginx start"
fi

# Summary
echo ""
echo "------------------------------------------------------------------------------"
echo "                    NGinx + PHP5-FPM installation finished"
echo "------------------------------------------------------------------------------"
echo "NGinx configuration folder:       /etc/nginx"
echo "NGinx default site configuration: /etc/nginx/sites-enabled/default-site"
echo "NGinx default HTML root:          /var/www"
echo ""
echo "Installation script  log file:	$LOG_FILE"
echo ""
echo "Notes: If you use IpTables add the following rules"
echo "iptables -A INPUT -i lo -s localhost -d localhost -j ACCEPT"
echo "iptables -A OUTPUT -o lo -s localhost -d localhost -j ACCEPT"
echo "iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"
echo "iptables -A INPUT  -p tcp --dport http -j ACCEPT"
echo ""
echo "------------------------------------------------------------------------------"
echo ""

# Fin du script
https://raw.github.com/soukhoi47/bash/master/nginxautoinstall_CentOS.sh
