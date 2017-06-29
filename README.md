a Nagios server example on vagrant.
==========================================================================

# Features
```
	1. Nagios server / client
	    'nserver' => "192.168.82.170",
	    'nclient' => "192.168.82.171",
	2. sendmail
	3. open firewall
	4. nginx version: master branch
	   apache version: apache branch
```

# Run
```
	vagrant up
	#vagrant destroy -f && vagrant up

	# for mail setting	
	after build 2 VMs
	vagrant ssh nserver
	$ bash /vagrant/scripts/smtp.sh
```

# Site
```
	# add vagrant server in /etc/hosts 
	192.168.82.170 server.tz.com
	
 	http://server.tz.com/nagios
 	
 	nagiosadmin / nagiospasswd
```


