echo "generating keystore.p12"
openssl pkcs12 -export -in $FULLCHAIN_PEM -inkey $PRIVKEY_PEM -out keystore.p12 -name $SITE -CAfile $CHAIN_PEM -caname root -password pass:$PASS1
echo "generating keystore.jks"
keytool -importkeystore -deststorepass $PASS1 -destkeypass $PASS1 -destkeystore keystore.jks -srckeystore keystore.p12 -srcstoretype PKCS12 -srcstorepass $PASS1 -alias $SITE
echo "generating keystore.jks pkcs12"
keytool -importkeystore -srckeystore keystore.jks -srcstorepass $PASS1 -destkeystore keystore.jks -deststoretype pkcs12 
echo "generating cacerts.jks"
keytool -trustcacerts -keystore cacerts.jks -storepass $PASS2 -noprompt -importcert -file $CHAIN_PEM
