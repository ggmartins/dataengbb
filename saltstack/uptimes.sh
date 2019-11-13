#!/bin/bash

echo "***" >> uptimes.log
date '+%Y%m%d' >> uptimes.log
sudo salt 'test*' status.uptime | grep -A1 -E "days|test1" >> uptimes.log
