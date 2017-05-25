import crosscheck
import httpclient, json
import parsecfg
import strutils

var config = loadConfig("conf.ini")

let email = config.getSectionValue("", "email") 
let apiKey = config.getSectionValue("", "apiKey") 
let zoneKey = config.getSectionValue("", "zoneKey") 
let site = config.getSectionValue("", "site") 

let client = newHttpClient()
client.headers = newHttpHeaders({ 
  "X-Auth-Email": email,
  "X-Auth-Key": apiKey 
  })

proc getDnsRecords(): JsonNode = 
  let body = client.request("https://api.cloudflare.com/client/v4/zones/" & zoneKey & "/dns_records", httpMethod = HttpGet).body #,  body = $body)
  let j = parseJson(body)
  return j["result"]

proc getIdByName(name: string): string =
  for entry in getDnsRecords():
    if entry["name"].getStr() == name:
      return entry["id"].getStr()

proc printDnsRecords() =
  let body = client.request("https://api.cloudflare.com/client/v4/zones/" & zoneKey & "/dns_records", httpMethod = HttpGet).body
  let j = parseJson(body)
  # return j["result"]
  for site in j["result"]:
    echo site["name"].getStr().align(20), " ", site["zone_name"].getStr(), " ", site["id"].getStr() , " -> " , site["content"].getStr() # site

proc renewIP(name, id, ip: string) =
  client.headers["Content-Type"] = "application/json"

  let body =  %* {
    "type":"A",
    "name": name,
    "content":ip,
    # "ttl":120,
    "ttl": 1,
    "proxied":false
  }
 
  discard repr client.request("https://api.cloudflare.com/client/v4/zones/" & zoneKey & "/dns_records/" & id, httpMethod = HttpPut, body = $body)
  # TODO: Check if update succesful ;)

when isMainModule:
  var sites: seq[string] = @[]

  for site in readAll(open "sites.txt").split("\n"):
    if not site.strip().startsWith("#"):
      sites.add site

  let ip = getExternalIP(sites)
  echo "My external ip: ", ip
  
  let id = getIdByName(site)
  renewIP(site, id, ip)

  printDnsRecords()

