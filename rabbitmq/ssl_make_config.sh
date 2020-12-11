#/bin/bash

if [ ! -f .env ];then
  echo "ERROR: please edit ssl_env.template and rename it to .env"
  exit 1
fi
source .env

git checkout -- tls-gen
#git submodule add https://github.com/michaelklishin/tls-gen
git submodule update #get tls-gen for client certificate

if [ ! -f tls-gen/basic/result/client_key.pem ];then

  echo "INFO: generating self-signed certificate via tls-gen"
  cd tls-gen/basic; make PASSWORD=${RABBITMQ_PIKA_SSL_CLIENT_KEY_PASS}; make verify; make info
  echo "INFO: self-signed cert OK"

else

  echo "INFO: self-signed cert OK (existing files)"

fi

echo "WARN: make sure you bundle letsencrypt's certificate with tls-gen/basic/result/ca_certificate.pem on the server (ssl_options.cacertfile)"
