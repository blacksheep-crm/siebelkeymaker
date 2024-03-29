#!/bin/bash
# usage: make_fqdn_alias
ALIAS=$2
FQDN=$1
# set SANs example below, remove comment to use and replace "echo subjectAltName..."
SAN=",DNS.2:<machinename>nbe.com,DNS.3:*.<machinename>.nbe.com"
# CHANGE_ME! :)
JAVA="/path/to/JDK/bin"
SSL="/path/to/OpenSSL/bin"
SIEBEL="/siebel/keymaker"
PASSWORD="siebel"

# DO NOT CHANGE
OPENSSL_CONF="$SSL/openssl.cfg"
# set SAN=DNS.1:$FQDN
rm -rf "$SIEBEL/$FQDN"
mkdir "$SIEBEL/$FQDN"

"$JAVA"/keytool -genkey -alias "$ALIAS" -keystore "$SIEBEL/$FQDN/siebelkeystore.jks" -keyalg RSA -sigalg SHA256withRSA -dname "cn=$FQDN" -storepass "$PASSWORD" -keypass "$PASSWORD" -storetype JKS
"$JAVA"/keytool -list -v -keystore "$SIEBEL/$FQDN/siebelkeystore.jks" -storepass "$PASSWORD" -keypass "$PASSWORD"
"$JAVA"/keytool -certreq -alias "$ALIAS" -keystore "$SIEBEL/$FQDN/siebelkeystore.jks" -file "$SIEBEL/$FQDN/siebelkeystore.csr" -storepass "$PASSWORD" -keypass "$PASSWORD"
"$SSL"/openssl req -newkey rsa:2048 -keyout "$SIEBEL/$FQDN/cakey.pem" -out "$SIEBEL/$FQDN/careq.pem" -subj "/CN=$FQDN" -sha256 -passout pass:"$PASSWORD"
"$SSL"/openssl x509 -signkey "$SIEBEL/$FQDN/cakey.pem" -req -days 3650 -in "$SIEBEL/$FQDN/careq.pem" -out "$SIEBEL/$FQDN/caroot.cer" -extfile v3.txt -passin pass:"$PASSWORD"
"$JAVA"/keytool -printcert -v -file "$SIEBEL/$FQDN/caroot.cer"
echo "basicConstraints=CA:FALSE" >> "$SIEBEL/$FQDN/ext.cnf"
# echo "subjectAltName=DNS.1:$FQDN" >> "$SIEBEL/$FQDN/ext.cnf"
# set SANs example
echo "subjectAltName=DNS.1:$FQDN$SAN" >> "$SIEBEL/$FQDN/ext.cnf"
echo "extendedKeyUsage=serverAuth,clientAuth" >> "$SIEBEL/$FQDN/ext.cnf"
# copy ext.cnf "$SIEBEL/$FQDN/ext.cnf"
echo "1234" > "$SIEBEL/$FQDN/serial.txt"
"$SSL"/openssl x509 -CA "$SIEBEL/$FQDN/caroot.cer" -CAkey "$SIEBEL/$FQDN/cakey.pem" -CAserial "$SIEBEL/$FQDN/serial.txt" -req -in "$SIEBEL/$FQDN/siebelkeystore.csr" -out "$SIEBEL/$FQDN/siebelkeystoreCASigned.cer" -days 3650 -extfile "$SIEBEL/$FQDN/ext.cnf" -passin pass:"$PASSWORD"
"$JAVA"/keytool -import -alias "${ALIAS}ca" -file "$SIEBEL/$FQDN/caroot.cer" -keystore "$SIEBEL/$FQDN/siebelkeystore.jks" -storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt
"$JAVA"/keytool -import -alias "$ALIAS" -file "$SIEBEL/$FQDN/siebelkeystoreCASigned.cer" -keystore "$SIEBEL/$FQDN/siebelkeystore.jks" -storepass "$PASSWORD" -keypass "$PASSWORD"
"$JAVA"/keytool -list -v -keystore "$SIEBEL/$FQDN/siebelkeystore.jks" -storepass "$PASSWORD" -keypass "$PASSWORD"
echo "Use the following path for both keystore and truststore in all Siebel installations: $SIEBEL/$FQDN/siebelkeystore.jks"
echo "Use the following password for both keystore and truststore: $PASSWORD"
# uncomment below to create truststore
# "$JAVA"/keytool -import -alias "$ALIAS" -file "$SIEBEL/$FQDN/siebelkeystoreCASigned.cer" -keystore "$SIEBEL/siebeltruststore.jks" -storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt
# "$JAVA"/keytool -import -alias "${ALIAS}ca" -file "$SIEBEL/$FQDN/caroot.cer" -keystore "$SIEBEL/siebeltruststore.jks" -storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt
