import ipParser
import asyncdispatch, httpclient
import sequtils
import tables


var client = newAsyncHttpClient()

proc checkSites(sites: seq[string]): Future[seq[seq[string]]] {.async.} =
  var buf: string = ""
  result = @[]
  for site in sites:
    buf = await client.getContent(site)
    try:
      result.add(toSeq(buf.parseIps()))
    except Exception as exp:
      echo "broken: ", site
      # echo repr exp
      # echo buf
      # break
      # echo exp.trace

proc getExternalIP*(sites: seq[string]): string = 
  var sitess = waitFor checkSites(sites)
  var sitecount = newCountTable[string]();
  for sitesAr in sitess:
    for site in sitesAr.deduplicate():
      sitecount.inc(site)

  # echo sitecount
  return sitecount.largest[0]


when isMainModule:
  var sites = @[
    "http://ipecho.net/plain", 
    # "https://www.wieistmeineip.de", # BILD wäh
    "https://www.iplocation.net/find-ip-address",
    # "https://www.ebay.de",
    # "https://www.paypal.de",
    # "https://www.apnic.net/get-ip/"
    "https://api.ipify.org/?format=json",
    "http://ip.42.pl/raw",
    "https://duckduckgo.com/?q=whats+my+ip&ia=answer",
  ]
  echo getExternalIP(sites)


