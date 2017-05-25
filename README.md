"dynamic dns" with cloudflare 

how it works:

- it visits bunch of "how is my ip" sites
- assume the most often seen ip(v4 only!) is your ip
- sets "A" dns record via cloudflare api


configuration:
fill the config
	email = "your@email.example"
	apiKey = "yourCloudflareApiKey"
	zoneKey = "yourZoneId"
	site = "server.yoursite.example"

extend the sites.txt list with your favourite ip resolver sites if you like

- compile renewIP
- call renewIP periodically to refresh your cloudflare dns record
