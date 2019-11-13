#!/bin/python

import os
import sys
import tarfile
import json
import time
import re
import glob
import psycopg2
import collections
from psycopg2 import IntegrityError
from psycopg2 import DatabaseError
from datetime import datetime
from collections import OrderedDict

tday=datetime.now().strftime("%Y%m%d")
#tday="20181201"
if int(datetime.now().strftime("%H")) < 7:
  print ("too early, not processing..")
  sys.exit()

def check_out_tgzfile_ext(fullpath, file):
 n = -1
 cachefile=os.path.join("reportstatus/", file+".ext.cache")
 if os.path.isfile(cachefile):
   f=open(cachefile, "r")
   if f is not None:
     try:
       r="".join(f.readlines())
       #n=int(f.read())
       n=int(r.split("|")[0])
       j=json.loads(r.split("|")[1])
     except ValueError as ve:
       os.remove(cachefile)
       n=-3
     return n,j

 try:
  t = tarfile.open(fullpath)
  try:
    files = t.getmembers() #todo try catch this
  except IOError as ioe2:
    print("[%d] Unable to process tgz file:" + fullpath, id)
  tmplines = []
  dev = {}
  app = {}
  n = 0
  for f in files:
    tgzfile=t.extractfile(f)
    if tgzfile is not None:
      try:
        #dev = {}
        if f.path.endswith(".tar.gz"):
          try:
            tfile=tarfile.open(fileobj=tgzfile)
            tfiles = tfile.getmembers()
            for tf in tfiles:
               l=tfile.extractfile(tf).readlines()
               for line in l:
                 m=re.match( r'.*"Device":"(.*?)"', line)
                 if m:
                   try:
                     dev[m.group(1)]=dev[m.group(1)] + 1
                   except:
                     dev[m.group(1)]=1    
                 m=re.match( r'.*"Meta":"(.*?)"', line)
                 if m:
                   try:
                     if m.group(1) != '': 
                       app[m.group(1)]=app[m.group(1)] + 1
                   except:
                     if m.group(1) != '': 
                       app[m.group(1)]=1
          except:
            print("Unexpected error:", sys.exc_info()[0])
      except:
        print("fail 2")
  for k in dev.keys():
    if k != "ff:ff:ff:ff:ff:ff" and k != "":
      n=n+1

  if n > 0:
    f=open(cachefile, "w")
    if f is not None:
      f.write("%d|%s\n" % (n, json.dumps(app)))
      f.close()
 except Exception as e:
  print ("check_out_tgzfile_ext:"+str(e))
  return -2, None
 return n, app

if os.path.isfile("reportstatus_ext.lock"):
  print ("running instance. exiting...")
  sys.exit(1)

lock=open("reportstatus_ext.lock", "w")
lock.close()

with open('reportstatus.log.salt.json') as f:
    lines = f.readlines()

print("Connecting to "+os.getenv("PSQL_DB")+" ...")
try:
  conn = psycopg2.connect("dbname='"+os.getenv("PSQL_DB")+"' user='"+os.getenv("PSQL_USER")+"' host='"+os.getenv("PSQL_HOST")+"' password='"+os.getenv("PSQL_PASS")+"'")
  conn.set_session(autocommit=True)
  print("Done.")
except Exception as e:
  print str(e)
  print("Unable to connect to the database. Exiting...")
  sys.exit(1)

cur = conn.cursor()

files=sorted(glob.glob("data/test_*/"+tday+"*"))
#files=sorted(glob.glob("/home/appflow/salt/data/test_*/"+tday+"*"))
#print(files)
for f in files:
  ssid=os.path.basename(os.path.dirname(f))
  datn, j=check_out_tgzfile_ext(f, os.path.basename(f))
  sout=""
  if j is not None:
    d=OrderedDict(sorted(j.items(), key=lambda x: x[1], reverse=True))
    for k in d:
      sout+=str(k).replace(" ", "_")+":"+str(d[k])+","
  try:
    cur.execute("INSERT INTO status_datafile VALUES (%s,%s,%s,%s,%s,%s,%s) "+\
                          "RETURNING ssid", (tday, ssid, None, datn, None, None, sout))
    inserted=cur.fetchone()
    if inserted is None:
      print("INSERT status_datafile error: "+ssid)
      continue
  except IntegrityError as ke:
    continue
  
ssid=None
bmid=None

print str(lines)
for l in lines:
  if "test_" in l:
    d=json.loads("{"+l+"}")
    ssid=d.keys()[0]
    v=d[ssid]
    bmid="N/A"
    devn=0
    appe=False
    if len(v) > 16:
      bmid=v[:14]
      devn=int(v[15:len(v)].split('\n')[0])
      appe="traffic-analysis" in v
      if bmid[:2] == "PI":
        #print "ssid:"+ssid
        #print "mbid:"+bmid
        #print "devn:"+str(devn)
        #print "appe:"+str(appe)
        file=tday+"-"+ssid+".tgz"
        full=os.path.join("data/", os.path.join(ssid, file))
        datn, j=check_out_tgzfile_ext(full, file)
        sout=""
        if j is not None:
          d=OrderedDict(sorted(j.items(), key=lambda x: x[1], reverse=True))
          for k in d:
            sout+=str(k).replace(" ", "_")+":"+str(d[k])+","
        try:
          if ssid == 'test_1666':
             print "test_1666 sout:"+sout
          if ssid == 'test_1267':
             print "test_1267 sout:"+sout
          cur.execute("UPDATE status_datafile SET bmid=%s, devn=%s, appe=%s, sout=%s "+\
                          "WHERE datestr=%s AND ssid=%s RETURNING bmid", (bmid, devn, appe, sout, tday, ssid))
          update=cur.fetchone()
          if update is None:
            #print("INSERT status_datafile error: "+ssid)
            cur.execute("INSERT INTO  status_datafile VALUES (%s,%s,%s,%s,%s,%s,%s) "+\
                          "RETURNING ssid", (tday, ssid, bmid, datn, devn, appe, sout))
            continue
        except IntegrityError as ke:
          continue
        except DatabaseError as de:
          print(str(de))
          continue 
    else:
      bmid="N/A"

os.remove("reportstatus_ext.lock")
