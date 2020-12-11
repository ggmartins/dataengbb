#/bin/bash

docker run -d -it --hostname=\
	-e RABBITMQ_LOGS=/tmp/log\
	-e RABBITMQ_DEFAULT_USER=\
	-e RABBITMQ_DEFAULT_PASS=\
	-e RABBITMQ_SSL_CACERTFILE=/cert/chain_bundle2.pem \
	-e RABBITMQ_SSL_CERTFILE=/cert/cert.pem\
	-e RABBITMQ_SSL_KEYFILE=/cert/privkey.pem\
	-e RABBITMQ_SSL_FAIL_IF_NO_PEER_CERT=true\
	-e RABBITMQ_SSL_VERIFY=verify_peer\
	--name rabbitmq1-verifypeer -p ... :5671 -p ... :15672\
	-v ... /rabbitmq/var/log:/tmp/log\
       	-v ... /rabbitmq/var/lib/rabbitmq:/var/lib/rabbitmq\
       	-v ... /cert/:/cert/ rabbitmq:3.8.9-management 
