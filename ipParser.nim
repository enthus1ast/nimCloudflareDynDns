import strscans
import strutils

iterator parseIps*(soup: string): string =
  # echo soup
  var a,b,c,d : int
  var buf: string = ""
  var idx = 0
  var ch: char
  while idx < soup.len:
    ch = soup[idx]
    # echo ch, ":", idx , ":", soup.len
    # if ch in "1234567890":
    if ch in Digits:
      try:
        if soup[idx..^1].scanf("$i.$i.$i.$i", a,b,c,d):
          # buf.setLen(0)
          buf = "$1.$2.$3.$4" % [$a,$b,$c,$d]
          if (a > 254 or a < 0)  or
             (b > 254 or b < 0)  or
             (c > 254 or c < 0)  or
             (d > 254 or d < 0)  :
             idx.inc(buf.len)
             continue
          yield buf
          idx.inc buf.len
      except Exception as exp:
        # idx.inc # cause numbers could be too big to cast to int
        # echo 
        # echo repr exp
        # echo soup[0..idx]
        # break
        discard
    idx.inc


when isMainModule:
  import sequtils
  echo toSeq(parseIps "hashdjasdhajksdjashdkjhaskh998.197.89.196jasdjkl193.197.89.196ajs193.197.89.196dklajsdk")
  # echo toSeq(parseIps "hashdjasdhajksdjashdkjhaskh196jasdjkl19.196ajs193..196dklajsdk81.")    