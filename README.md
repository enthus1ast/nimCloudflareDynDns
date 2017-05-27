"dynamic dns" with cloudflare 
=============================

how it works
============

- it visits bunch of "how is my ip"/resolver sites
- assume the most often seen ip(v4 only!) is your ip
- sets "A" dns record via cloudflare api


configuration
=============

fill the config
```
	email = "your@email.example"
	apiKey = "yourCloudflareApiKey"
	zoneKey = "yourZoneId"
	domains = "server.yoursite.example,another.yoursite.example"
```

if you like extend the sites.txt list with your favourite ip resolver sites.


- compile renewIP: `nim c -d:release renewIP.nim`
- call renewIP periodically (via cron, sheduled task, etc...) to refresh your cloudflare dns record:

