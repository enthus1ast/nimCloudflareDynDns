import httpclient, json, parsecfg, strutils, os, asyncdispatch, strformat
import crosscheck

var config = loadConfig(getCurrentDir() / "conf.ini")
const api = "https://api.cloudflare.com/client/v4/zones/"

let email = config.getSectionValue("", "email")
let apiKey = config.getSectionValue("", "apiKey")
let zoneKey = config.getSectionValue("", "zoneKey")
let domains = config.getSectionValue("", "domains").split(",")

let client = newAsyncHttpClient()
client.headers = newHttpHeaders({ 
  "X-Auth-Email": email,
  "X-Auth-Key": apiKey
  })

proc getDnsRecords(): Future[JsonNode] {.async.} = 
  try:
    let resp = await client.request(api & zoneKey & "/dns_records", httpMethod = HttpGet)
    let j = parseJson(await resp.body)
    return j["result"]
  except:
    echo "could not get the dns_records"
    echo getCurrentExceptionMsg()
    return 

proc getIdByName(name: string): Future[string] {.async.} =
  for entry in (await getDnsRecords()):
    if entry["name"].getStr() == name:
      return entry["id"].getStr()

proc printDnsRecords() {.async.} =
  let dnsRecords = await getDnsRecords()
  for site in dnsRecords:
    let name = site["name"].getStr().align(20)
    let zoneName = site["zone_name"].getStr()
    let id = site["id"].getStr()
    let content = site["content"].getStr()
    echo fmt"{name} {zoneName} {id} -> {content}"
    
proc renewIP(name, id, ip: string) {.async.} =
  client.headers["Content-Type"] = "application/json"
  let body =  %* {
    "type":"A",
    "name": name,
    "content":ip,
    # "ttl":120,
    "ttl": 1,
    "proxied":false
  }
  discard await (client.request(api & zoneKey & "/dns_records/" & id, httpMethod = HttpPut, body = $body))

proc main() {.async.} = 
  var sites: seq[string] = @[]

  for site in readAll(open "sites.txt").split("\n"):
    if not site.strip().startsWith("#"):
      sites.add site

  let ip = await getExternalIP(sites)
  echo "My external ip: ", ip
  
  for domain in domains:
    echo "Updating: ", domain
    let id = await getIdByName(domain)
    await renewIP(domain, id, ip)

  echo "All configured DNS records:"
  await printDnsRecords()

when isMainModule:
  waitFor main()
