/:
  file.recurse:
    - file_mode: 600
    - source: salt://deploy/rpi3

/ta/traffic-analysis:
  file.managed:
    - mode: 700

/ta/wrapper.sh:
  file.managed:
    - mode: 700

/etc/cron.d/cron-traffic-analysis:
  file.managed:
    - mode: 700

/ta/scripts/run.sh:
  file.managed:
    - mode: 700
