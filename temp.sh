 yum install --enablerepo=remi php-sqlite php-json  php-curl zip git
 yum install curl curl-devel
 mp3info
 
cd /home/alexandre
wget ftp://ftp.ibiblio.org/pub/linux/apps/sound/mp3-utils/mp3info/mp3info-0.8.5.tgz
tar zxvf mp3info-0.8.5.tgz
rm -rf mp3info-0.8.5.tgz
cd ./mp3info-0.8.5
make mp3info
make install
rm -rf ./mp3info-0.8.5









