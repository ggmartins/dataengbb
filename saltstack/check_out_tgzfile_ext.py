#!/usr/bin/python
import os
import sys
#import argparse
#import glob
import tarfile
#import json
import time
import re

tgz = sys.argv[1]

try:
 t = tarfile.open(tgz)
 try:
   files = t.getmembers() #todo try catch this
 except IOError as ioe2:
   print("[%d] Unable to process tgz file:" + tgz, id)
 tmplines = []
 dev = {}
 app = {}
 for f in files:
   tgzfile=t.extractfile(f)
   if tgzfile is not None:
      try:
        dev = {}
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
 n = 0
 for k in dev.keys():
   if k != "ff:ff:ff:ff:ff:ff" and k != "":
     n=n+1
 if n == 0:
   print "ZERO|"+str(app)
 else:
   print str(dev)
   print str(n)+"|"+str(app)

except:
  print("fail 3")
