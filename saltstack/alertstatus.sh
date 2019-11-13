#!/bin/bash
datestr=$(date +%Y%m%d)
hour=$(date +%H)
cd alertstatus
if [ -f "alert."$datestr ]; then
  echo "alert already sent today"
  exit 0
fi

if [ $hour -lt "7" ]; then
  echo "too early not processing"
  exit 0
fi


wget -q https://projectbismark.net:8080/bismark/status/w/f6d2/deployment.txt -O deployment.txt

if grep -q "Last seen" deployment.txt; then
  grep  "Last seen" deployment.txt >> "alert."$datestr
fi

if grep -q "AppEnabled:f" deployment.txt; then
  grep  "AppEnabled:f" deployment.txt >> "alert."$datestr
fi

if grep -q "DevsInDatafile:0" deployment.txt; then
  grep  "DevsInDatafile:0" deployment.txt >> "alert."$datestr
fi

if grep -q "DevsInDatafile:-2" deployment.txt; then
  grep  "DevsInDatafile:-2" deployment.txt >> "alert."$datestr
fi


if [ -f "alert."$datestr ]; then
  cat "alert."$datestr | mail -s "Alert WSJ Deployment" "ggmartins@"
  #cat "alert."$datestr | mail -s "Alert WSJ Deployment" "ggmartins@"
fi

cd -
