sudo su
set -x

echo "Reading config...." >&2
source /vagrant/setup.rc

export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get install nagios-nrpe-server nagios-plugins -y

sed -i "s|#server_address=127.0.0.1|server_address=192.168.82.170|g" /etc/nagios/nrpe.cfg
sed -i "s|allowed_hosts=127.0.0.1|allowed_hosts=127.0.0.1,192.168.82.171|g" /etc/nagios/nrpe.cfg

sudo sh -c "echo '' >> /etc/nagios/nrpe.cfg"
sudo sh -c "echo 'command[check_hda1]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /dev/sda1' >> /etc/nagios/nrpe.cfg"

service nagios-nrpe-server restart

exit 0

apt-get install openssl libssl-dev xinetd unzip -y

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
sed -i "s|allowed_hosts=127.0.0.1|allowed_hosts=127.0.0.1,192.168.82.171|g" /usr/local/nagios/etc/nrpe.cfg

##########################################
# firewall rules
##########################################
sudo mkdir -p /etc/iptables
sudo cp /vagrant/etc/iptables/rules /etc/iptables/rules

sudo sed -i "s/^iptables-restore//g" /etc/network/if-up.d/iptables
sudo sh -c "echo 'iptables-restore < /etc/iptables/rules' >> /etc/network/if-up.d/iptables"
sudo iptables-restore < /etc/iptables/rules

iptables -I INPUT -m tcp -p tcp --dport 5666 -j ACCEPT