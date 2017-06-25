sudo su
set -x

echo "Reading config...." >&2
source /vagrant/setup.rc

export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get install openssl libssl-dev xinetd unzip -y

useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios

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
make install
make install-xinetd
make install-daemon-config

sudo sed -i "s/127.0.0.1/127.0.0.1 192.168.82.170/g" /etc/xinetd.d/nrpe

# for make ssh connection
mkdir -p /root/.ssh
sudo cp /vagrant/etc/known_hosts /root/.ssh/known_hosts

##########################################
# restart services
##########################################
service xinetd restart
#service xinetd stop

#tail -f /var/log/syslog

exit 0

##########################################
# firewall rules
##########################################
sudo mkdir -p /etc/iptables
sudo cp /vagrant/etc/iptables/rules /etc/iptables/rules

sudo sed -i "s/^iptables-restore//g" /etc/network/if-up.d/iptables
sudo sh -c "echo 'iptables-restore < /etc/iptables/rules' >> /etc/network/if-up.d/iptables"
sudo iptables-restore < /etc/iptables/rules

iptables -I INPUT -m tcp -p tcp --dport 5666 -j ACCEPT

# make ssh connection
root@nclient:/home/vagrant# ssh vagrant@192.168.82.170
The authenticity of host '192.168.82.170 (192.168.82.170)' can't be established.
ECDSA key fingerprint is SHA256:RFvpNfxapZ+GuMNh+1KW2vydOaV9ldcwW/ZGv3NbgrA.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.82.170' (ECDSA) to the list of known hosts.

exit 0



