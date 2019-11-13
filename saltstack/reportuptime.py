#!/usr/bin/python

import os
import sys
import tarfile
import re
import glob
from datetime import datetime
from collections import OrderedDict

def check_out_tgzfile_ext(fullpath, file, d, ssid):
 uptime = 0
 uptime_total = 0
 try:
  t = tarfile.open(fullpath)
  try:
    files = t.getmembers() #todo try catch this
  except IOError as ioe2:
    print("[%d] Unable to process tgz file:" + fullpath, id)
    return 0, 24 * 60
  total_files = 0 
  firstts = 0
  for f in files:
    r=re.findall("^([0-9]{8})/ta\.([0-9]{10})\.out.*", f.name)
    if len(r) > 0:
      if firstts == 0:
         firstts = int(r[0][1]) 
         if d[ssid]["lastts"] > 0 and (firstts - d[ssid]["lastts"]) > (60 * 60) + 30: #threshold here in secs
            uptime_total += ((firstts - d[ssid]["lastts"]) / 60) - 60
      else:
        if d[ssid]["lastts"] > 0 and (int(r[0][1]) - d[ssid]["lastts"]) > (60 * 60) + 30: #threshold here in secs
          uptime_total += ((int(r[0][1]) - d[ssid]["lastts"]) / 60) - 60
      uptime += 60
      total_files += 1
      d[ssid]["lastts"] = int(r[0][1])
      uptime_total += 60
  d[ssid]["uptime"] += uptime

 except Exception as e:
  print ("check_out_tgzfile_ext:"+str(e))
 return uptime, uptime_total

files=sorted(glob.glob("data/test_*/*.tgz"))
uptime_total = 0
uptime_verif = 0
d = {}

wlist = []
with open("reportuptime.white.list") as l:
  for w in l.readlines():
    wlist.append(w.strip("\n\r,"))

print "Processing: " + str(wlist) + "\n"
for f in files:
  ssid=os.path.basename(os.path.dirname(f))
  if ssid not in wlist:
    continue
  if ssid not in d.keys():
    d[ssid] = {}
    d[ssid]["uptime"] = 0
    d[ssid]["lastts"] = 0
  
  uptime=check_out_tgzfile_ext(f, os.path.basename(f), d, ssid)
  if uptime[0] > 24 * 60:
     print "Warning: "+ssid+" uptime grater than 24*60: " + str(uptime[0]) + "  uptime_total: "+ str(uptime[1]) 
     uptime = (24 * 60, 24 * 60)
  uptime_verif += uptime[0]
  uptime_total += uptime[1]
  
print "uptime_total:" + str(uptime_total) + " uptime_verify:" + str(uptime_verif) + "\n"
print d
