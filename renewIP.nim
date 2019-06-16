import crosscheck
import httpclient, json
import parsecfg
import strutils

type DnsType = enum 
  DnsA = "A", 
  DnsAAAA = "AAAA"
var config = loadConfig("conf.ini")
const api = "https://api.cloudflare.com/client/v4/zones/"

let email = config.getSectionValue("", "email") 
let apiKey = config.getSectionValue("", "apiKey") 
let zoneKey = config.getSectionValue("", "zoneKey") 
let domains = config.getSectionValue("", "domains").split(",") # ipv4
let domains6 = config.getSectionValue("", "domains6").split(",") # ipv6

let client = newHttpClient()
client.headers = newHttpHeaders({ 
  "X-Auth-Email": email,
  "X-Auth-Key": apiKey 
  })

proc getDnsRecords(dnsType: DnsType): JsonNode = 
  let url = api & zoneKey & "/dns_records?type=" & $dnsType
  let body = client.request(url, httpMethod = HttpGet).body
  let j = parseJson(body)
  return j["result"]

proc getIdByName(name: string, dnsType: DnsType): string =
  for entry in getDnsRecords(dnsType):
    if entry["name"].getStr() == name:
      return entry["id"].getStr()

proc printSite(site: JsonNode) = 
  echo site["name"].getStr().align(20), " ", site["zone_name"].getStr(), " ", site["id"].getStr() , " -> " , site["content"].getStr() # site

proc printDnsRecords() =
  var jA = getDnsRecords(DnsA)
  var jAAAA = getDnsRecords(DnsAAAA)
  # return j["result"]
  for site in jA:
    printSite(site)
  for site in jAAAA:
    printSite(site)

proc renewIP(name, id, ip: string, dnsType: DnsType) =
  client.headers["Content-Type"] = "application/json"
  let body =  %* {
    "type": $dnsType,
    "name": name,
    "content":ip,
    # "ttl":120,
    "ttl": 1,
    "proxied":false
  }
  discard repr client.request(api & zoneKey & "/dns_records/" & id, httpMethod = HttpPut, body = $body)

when isMainModule and true:
  printDnsRecords() 
  quit()
when isMainModule and false:
  var sites: seq[string] = @[]

  for site in readAll(open "sites.txt").split("\n"):
    if not site.strip().startsWith("#"):
      sites.add site

  # For ipv4
  let ip = getExternalIP(sites)
  echo "My external ip: ", ip
  
  for domain in domains:
    echo "Updateing: ", domain
    let id = getIdByName(domain)
    renewIP(domain, id, ip, DnsA)

  # For ipv6
  let ip6 = getExternalIP6(sites)
  echo "My external ip6: ", ip6
  
  for domain6 in domains6:
    echo "Updateing6: ", domain6
    let id = getIdByName(domain6)
    renewIP(domain6, id, ip6, DnsAAAA)

  printDnsRecords()



# 2a02:908:100:b:15dc:172a:527e:79b0