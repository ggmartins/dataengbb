#please run `make -f ssl.Makefile config` and pray

config:
	bash ssl_make_config.sh

config_clean:
	rm -Rf tls-gen

test_serv:
	openssl s_server -accept 5671 -cert /usr/local/etc/rabbitmq/cert.pem -CAfile /usr/local/etc/rabbitmq/chain_bundle.pem -key /usr/local/etc/rabbitmq/privkey.pem

test_client:
	openssl s_client -connect localhost:5671 -cert tls-gen/basic/result/client_certificate.pem -key tls-gen/basic/result/client_key.pem -pass pass:${RABBITMQ_PIKA_SSL_CLIENT_KEY_PASS}
