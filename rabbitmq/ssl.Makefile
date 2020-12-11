#please run `make -f ssl.Makefile config` and pray

config:
	bash ssl_make_config.sh

config_clean:
	rm -Rf tls-gen
