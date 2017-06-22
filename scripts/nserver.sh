#!/bin/bash

sudo su
set -x

echo "Reading config...." >&2
source /vagrant/setup.rc

# https://websetnet.com/install-nagios-server-monitoring-ubuntu-16-04/
# https://www.digitalocean.com/community/tutorials/how-to-install-nagios-4-and-monitor-your-servers-on-ubuntu-14-04

export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get install wget build-essential apache2 php apache2-mod-php7.0 php-gd libgd-dev sendmail unzip -y
apt-get install build-essential libgd2-xpm-dev openssl libssl-dev xinetd apache2-utils unzip -y

##########################################
# install nagios
##########################################
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagios,nagcmd www-data

curl -L -O https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.1.1.tar.gz
tar xvf nagios-*.tar.gz
cd nagios-*
./configure --with-nagios-group=nagios --with-command-group=nagcmd

make all
sudo make install
sudo make install-commandmode
sudo make install-init
sudo make install-config
/usr/bin/install -c -m 644 sample-config/httpd.conf /etc/apache2/sites-available/nagios.conf

cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

##########################################
# install nagios plugins
##########################################
cd /home/vagrant
curl -L -O http://nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz 
tar xvf nagios-plugins-*.tar.gz
cd nagios-plugins-*
./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
make
make install

##########################################
# install nrpe
##########################################
cd /home/vagrant
curl -L -O http://downloads.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.15/nrpe-2.15.tar.gz 
tar xvf nrpe-*.tar.gz
cd nrpe-*
./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
make all
sudo make install
sudo make install-xinetd
sudo make install-daemon-config

sed -i "s|#server_address=127.0.0.1|server_address=192.168.82.170|g" /usr/local/nagios/etc/nrpe.cfg
sed -i "s|allowed_hosts=127.0.0.1|allowed_hosts=127.0.0.1,localhost,192.168.82.170,192.168.82.171|g" /usr/local/nagios/etc/nrpe.cfg
service nagios-nrpe-server restart

sudo sed -i "s/127.0.0.1/127.0.0.1 192.168.82.170/g" /etc/xinetd.d/nrpe

##########################################
# setting nagios
##########################################
sudo sh -c "echo '' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '	define command{' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '      command_name check_nrpe' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '      command_line \$USER1\$/check_nrpe -H \$HOSTADDRESS\$ -c \$ARG1\$' >> /usr/local/nagios/etc/objects/commands.cfg"
sudo sh -c "echo '	}' >> /usr/local/nagios/etc/objects/commands.cfg"

sed -i "s|#cfg_dir=/usr/local/nagios/etc/servers|cfg_dir=/usr/local/nagios/etc/servers|g" /usr/local/nagios/etc/nagios.cfg 
mkdir -p /usr/local/nagios/etc/servers
sed -i "s|nagios@localhost|doogee323@gmail.com|g" /usr/local/nagios/etc/objects/contacts.cfg

##########################################
# setting htpasswd
##########################################
sudo a2enmod rewrite
sudo a2enmod cgi

PASSWORD=nagiospasswd
htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin $PASSWORD
echo Password set to: $PASSWORD

##########################################
# init.d nagios
##########################################
cd /etc/init.d/
cp /etc/init.d/skeleton /etc/init.d/nagios
sed -i "s|DESC=|#DESC=|g" /etc/init.d/nagios
sed -i "s|DAEMON=|#DAEMON=|g" /etc/init.d/nagios

sudo sh -c "echo 'DESC=\"Nagios\"' >> /etc/init.d/nagios"
sudo sh -c "echo 'NAME=nagios' >> /etc/init.d/nagios"
sudo sh -c "echo 'DAEMON=/usr/local/nagios/bin/nagios' >> /etc/init.d/nagios"
sudo sh -c "echo 'DAEMON_ARGS=\"-d /usr/local/nagios/etc/nagios.cfg\"' >> /etc/init.d/nagios"
sudo sh -c "echo 'PIDFILE=/usr/local/nagios/var/$NAME.lock' >> /etc/init.d/nagios"
chmod +x /etc/init.d/nagios
update-rc.d nagios defaults

sudo ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/
sudo chown -Rf nagios:nagios /usr/local/nagios

##########################################
# firewall rules
##########################################
sudo mkdir -p /etc/iptables
sudo cp /vagrant/etc/iptables/rules /etc/iptables/rules

sudo sed -i "s/^iptables-restore//g" /etc/network/if-up.d/iptables
sudo sh -c "echo 'iptables-restore < /etc/iptables/rules' >> /etc/network/if-up.d/iptables"
sudo iptables-restore < /etc/iptables/rules

iptables -I INPUT -m tcp -p tcp --dport 5666 -j ACCEPT

##########################################
# restart services
##########################################
service apache2 restart
sudo service xinetd restart
#/etc/init.d/nagios restart
service nagios restart

#http://192.168.82.170/nagios
# nagiosadmin / nagiospasswd

##########################################
# add a host
##########################################
mkdir -p /usr/local/nagios/etc/servers
sudo cp /vagrant/etc/nagios/ubuntu_host.cfg /usr/local/nagios/etc/servers/ubuntu_host.cfg
# vi /usr/local/nagios/etc/objects/commands.cfg
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

exit 0
