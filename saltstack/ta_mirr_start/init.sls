ta:
  cmd.run:
    - name: ./wrapper.sh -s -i eth0 -m mirror 
    - cwd: /ta
    - timeout: 1
    - ignore_timeout: True
