#!/bin/bash

sudo su
set -x

echo "Reading config...." >&2
source /vagrant/setup.rc

##########################################
# install sendmail
##########################################
sudo sh -c "echo 'nserver.mydomain.eu' > /etc/hostname"
sudo hostname nserver.mydomain.eu

sudo sh -c "echo '' >> /etc/hosts"
sudo sh -c "echo '127.0.0.1   nserver.mydomain.eu' >> /etc/hosts"

export DEBIAN_FRONTEND=noninteractive
#apt-get purge sendmail -y
apt-get install sendmail -y
sed -i "s|127.0.0.1|0.0.0.0|g" /etc/mail/sendmail.mc
sudo m4 /etc/mail/sendmail.mc
sudo sh -c "echo '' >> /etc/mail/access"
sudo sh -c "echo '192.168.0 RELAY' >> /etc/mail/access"
systemctl status sendmail.service
#sudo service sendmail restart

##########################################
# install postfix
##########################################
export DEBIAN_FRONTEND=noninteractive
#sudo apt-get purge postfix libsasl2-modules ca-certificates mailutils -y
sudo apt-get install postfix libsasl2-modules ca-certificates mailutils -y

sed -i "s|myhostname = |#myhostname = |g" /etc/postfix/main.cf
sed -i "s|alias_maps = |myhostname = nserver.mydomain.eu\nalias_maps = |g" /etc/postfix/main.cf
sed -i "s|relayhost = |relayhost = [smtp.gmail.com]:587|g" /etc/postfix/main.cf

sudo sh -c "echo '' >> /etc/postfix/main.cf"
sudo sh -c "echo '### add Gmail SMTP configuration' >> /etc/postfix/main.cf"
sudo sh -c "echo 'smtp_sasl_auth_enable = yes' >> /etc/postfix/main.cf"
sudo sh -c "echo 'smtp_sasl_security_options = noanonymous' >> /etc/postfix/main.cf"
sudo sh -c "echo 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' >> /etc/postfix/main.cf"
sudo sh -c "echo 'smtp_use_tls = yes' >> /etc/postfix/main.cf"
sudo sh -c "echo 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt' >> /etc/postfix/main.cf"

touch /etc/postfix/sasl_passwd
sudo sh -c 'echo "[smtp.gmail.com]:587    doogee323@gmail.com:xxxxxxx" > /etc/postfix/sasl_passwd'

touch /etc/postfix/virtual
sudo postmap /etc/postfix/virtual
sudo postmap /etc/postfix/sasl_passwd
sudo service postfix reload

#sudo killall sendmail
#service sendmail stop
service postfix restart
service sendmail restart

sudo echo "body of your email" | sudo mail -s "This is a Subject" -a "From: doogee323@example.org" doohee323@gmail.com
# tail -f /var/log/syslog

exit 0