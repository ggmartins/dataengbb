#!/bin/python
import os,sys,traceback
import tarfile
import json
import time
import re
import glob
import psycopg2
#import psycopg2.errors
import collections
import email.utils
from psycopg2 import IntegrityError
from psycopg2 import DatabaseError
from datetime import datetime
from collections import OrderedDict

def sizeof_fmt(num, suffix='B'):
    for unit in ['','K','M','G','T','P','E','Z']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Y', suffix)

with open('reportstatus.ext2.json', 'r') as f:
    confjson = json.load(f)
ids=[i['id'] for i in confjson]

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

files=sorted(glob.glob("data/test_*/*.tar.gz"))
for f in files:
  ssid=os.path.basename(os.path.dirname(f))
  dbid=os.path.basename(f)

  if ssid not in ids:
    print("skipping: "+ ssid)
    continue
  print(ssid+"-"+dbid)
  
  try:
    t = tarfile.open(f)
    try:
      files = t.getmembers() #todo try catch this
    except IOError as ioe2:
      print("[%d] Unable to process tgz file:" + fullpath, id)
    tmplines = []
    j = None
    for f in files:
      jsonfile=t.extractfile(f)
      if jsonfile is not None:
        try:
          lines=jsonfile.readlines()
          f_frt = None
          f_lrt = None
          f_tbin = 0
          f_tbout = 0
          f_tbin_pp = ""
          f_tbout_pp = ""
          l_frt = None
          l_lrt = None
          l_tbin = 0
          l_tbout = 0
          l_tbin_pp = ""
          l_tbout_pp = ""

          for l in lines:
            #print(l)
            try:
              j=json.loads(l)
              if f_frt is None:
                if j['Info']['Type']=='Traffic' or j['Info']['Type']=='Capture':
                  f_frt=str(datetime(*email.utils.parsedate_tz(j['Info']['FirstReset'])[0:6]))
                  f_lrt=str(datetime(*email.utils.parsedate_tz(j['Info']['LastReset'])[0:6]))
                  f_tbin=j['Info']['TotalBytesIn']
                  f_tbout=j['Info']['TotalBytesOut']
                  f_tbin_pp=sizeof_fmt(j['Info']['TotalBytesIn'])
                  f_tbout_pp=sizeof_fmt(j['Info']['TotalBytesOut'])
                  l_frt=f_frt
                  l_lrt=f_lrt
                  l_tbin=f_tbin
                  l_tbout=f_tbout
                #print("f_tbin 1:"+str(j['Info']['TotalBytesIn']))
                #print("f_tbin 2:" + str(f_tbin))
              else:
                if j['Info']['Type']=='Traffic' or j['Info']['Type']=='Capture':
                  l_frt=str(datetime(*email.utils.parsedate_tz(j['Info']['FirstReset'])[0:6]))
                  l_lrt=str(datetime(*email.utils.parsedate_tz(j['Info']['LastReset'])[0:6]))
                  l_tbin=j['Info']['TotalBytesIn']
                  l_tbout=j['Info']['TotalBytesOut']
                  l_tbin_pp=sizeof_fmt(j['Info']['TotalBytesIn'])
                  l_tbout_pp=sizeof_fmt(j['Info']['TotalBytesOut'])
            except Exception as e0:
              #print(str(e0))
              #sys.exit(1)
              pass
          try:
            cur.execute("INSERT INTO status_meter VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) "+\
                        "RETURNING ssid", (dbid, ssid, f_frt, f_lrt, f_tbin, f_tbout, f_tbin_pp, f_tbout_pp,
                                                       l_frt, l_lrt, l_tbin, l_tbout, l_tbin_pp, l_tbout_pp))
            inserted=cur.fetchone()
            if inserted is None:
               print("INSERT status_meter error: "+ssid)
               continue
            #sys.exit(1)
          except IntegrityError as ke:
            print("INSERT status_meter integrity error: "+str(ke))
            continue
          except (Exception, psycopg2.DatabaseError) as error:
            print("process_traffic (DatabaseError): " + str(error))
            exc_type, exc_obj, exc_tb = sys.exc_info()
            fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
            print(exc_type, fname, exc_tb.tb_lineno)
            print("Exception: "+fname+" "+str(exc_tb.tb_lineno)+", "+str(error))
            print("INSERT INTO status_meter VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) " %\
                        (dbid, ssid, f_frt, f_lrt, f_tbin, f_tbout, f_tbin_pp, f_tbout_pp,
                                                       l_frt, l_lrt, l_tbin, l_tbout, l_tbin_pp, l_tbout_pp))
 
            continue
          #except psycopg2.errors.DataException as de:
          #  print("DataError: " + str(de))
          #  continue
        except Exception as e1:
           print("General Exception: " + str(e1))
           traceback.print_exc(file=sys.stdout)
  except Exception as e2:
    print(str(e2))
