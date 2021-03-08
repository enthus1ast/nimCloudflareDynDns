import ipParser
import asyncdispatch, httpclient
import sequtils
import tables
import strutils

var client = newAsyncHttpClient()

proc checkSites(sites: seq[string]): Future[seq[seq[string]]] {.async.} =
  var buf: string = ""
  result = @[]
  for siteRaw in sites:
    let site = siteRaw.strip()
    if site.len == 0: continue
    try:
      buf = await client.getContent(site)
    except:
      echo "could not get content from: ", site
      echo getCurrentExceptionMsg()
    try:
      result.add(toSeq(buf.parseIps()))
    except:
      echo "broken: ", site

proc getExternalIP*(sites: seq[string]): Future[string] {.async.} =
  var sitess = await checkSites(sites)
  var sitecount = newCountTable[string]();
  for sitesAr in sitess:
    for site in sitesAr.deduplicate():
      sitecount.inc(site)
  return sitecount.largest[0]

when isMainModule:
  var sites = @[
    "http://ip.code0.xyz",
    "http://ipecho.net/plain", 
    "https://www.iplocation.net/find-ip-address",
    "https://api.ipify.org/?format=json",
    "http://ip.42.pl/raw",
    "https://duckduckgo.com/?q=whats+my+ip&ia=answer",
  ]
  let ip = waitFor getExternalIP(sites)
  echo ip
  while true:
    let inp = readLine(stdin)
    echo waitFor checkSites(@[inp])


