ta:
  cmd.run:
    - name: ./wrapper.sh -s -i eth1 -m router 
    - cwd: /ta
    - timeout: 1
    - ignore_timeout: True
