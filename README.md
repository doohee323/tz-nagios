a Nagios server example on vagrant.
==========================================================================

# Features
```
	1. Nagios server / client
	    'nserver' => "192.168.82.170",
	    'nclient' => "192.168.82.171",
	2. open firewall
	3. nginx version: master branch
	   apache version: apache branch
```

# Run
```
	vagrant up
	#vagrant destroy -f && vagrant up
```

# Site
```
	# add vagrant server in /etc/hosts 
	192.168.82.170 server.tz.com
	
 	http://192.168.82.170/nagios
```


