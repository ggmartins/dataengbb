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
 res = {}
 for f in files:
   tgzfile=t.extractfile(f)
   if tgzfile is not None:
      try:
        res = {}
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
                     res[m.group(1)]=res[m.group(1)] + 1
                   except:
                     res[m.group(1)]=1    
          except:
            print("Unexpected error:", sys.exc_info()[0])
      except:
        print("fail 2")
 n = 0
 for k in res.keys():
   if k != "ff:ff:ff:ff:ff:ff" and k != "":
     n=n+1
 if n == 0:
   print "ZERO"
 else:
   print res
   print str(n)

except:
  print("fail 3")
