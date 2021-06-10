#!/usr/bin/env python3

import os
from pyftpdlib import servers
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.authorizers import DummyAuthorizer

authorizer = DummyAuthorizer()

authorizer.add_user(os.environ['NMFTPUSER'], os.environ['NMFTPPASS'], '.', perm='elradfmwMT')

handler = FTPHandler
handler.authorizer = authorizer

handler.banner = "Data Rescue FTP"

address = ("0.0.0.0", os.environ['NMFTPPORT'])  # listen on every IP on my machine on port 21
server = servers.FTPServer(address, FTPHandler)
server.serve_forever()
