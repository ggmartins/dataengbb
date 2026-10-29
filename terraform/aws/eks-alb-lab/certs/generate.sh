#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
umask 077
hostname="${1:-alb-lab.example.test}"
if [[ -e server.key || -e client-ca.key || -e client.key ]]; then
  echo "Certificates already exist. Reuse them, or explicitly remove the generated files to regenerate." >&2
  exit 1
fi

# The server certificate is imported into ACM. curl explicitly trusts this file.
cat > server.cnf <<EOF
[req]
prompt = no
distinguished_name = dn
x509_extensions = ext
[dn]
CN = ${hostname}
[ext]
subjectAltName = DNS:${hostname}
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
EOF
openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 7 \
  -keyout server.key -out server.crt -config server.cnf

cat > ca.cnf <<'EOF'
[req]
prompt = no
distinguished_name = dn
x509_extensions = ext
[dn]
CN = ALB Lab Client CA
[ext]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
EOF
openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 7 \
  -keyout client-ca.key -out client-ca.crt -config ca.cnf
openssl req -new -newkey rsa:2048 -nodes -sha256 \
  -keyout client.key -out client.csr -subj "/CN=lab-client"
cat > client.ext <<'EOF'
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
openssl x509 -req -sha256 -days 7 -in client.csr \
  -CA client-ca.crt -CAkey client-ca.key -CAcreateserial \
  -out client.crt -extfile client.ext
openssl verify -CAfile client-ca.crt -purpose sslclient client.crt
