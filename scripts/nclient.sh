sudo su
set -x

echo "Reading config...." >&2
source /vagrant/setup.rc

export DEBIAN_FRONTEND=noninteractive

##########################################
# install nagios
##########################################
apt-get -y update
apt-get install nagios-nrpe-server nagios-plugins -y
apt-get install openssl libssl-dev xinetd unzip -y

sed -i "s|#server_address=127.0.0.1|server_address=192.168.82.170|g" /etc/nagios/nrpe.cfg
sed -i "s|allowed_hosts=127.0.0.1|allowed_hosts=127.0.0.1,192.168.82.171|g" /etc/nagios/nrpe.cfg

sudo sh -c "echo '' >> /etc/nagios/nrpe.cfg"
sudo sh -c "echo 'command[check_hda1]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /dev/sda1' >> /etc/nagios/nrpe.cfg"

# for make ssh connection
mkdir -p /root/.ssh
sudo cp /vagrant/etc/known_hosts /root/.ssh/known_hosts

##########################################
# restart services
##########################################
service nagios-nrpe-server restart
service nagios-nrpe-server status
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



