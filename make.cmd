@echo off
rem usage: make fqdn alias
set ALIAS=%2
set FQDN=%1
rem CHANGE_ME! :)
set KEYMAKER_HOME=C:\Users\sadmin\Documents\keymaker_full
set JAVA=%KEYMAKER_HOME%\JDK\bin
set SSL=%KEYMAKER_HOME%\OpenSSL\bin
set PASSWORD=siebel
set CANAME=siebel-ca

rem DO NOT CHANGE
set OPENSSL_CONF=%SSL%\openssl.cfg
rem set SAN=,DNS.2:*.company.com,DNX.3:*.siebel.svc.cluster.local
set SAN=,DNS.2:*.sslip.io,DNS.3:*.company.com,DNS.4:*.vcn.oraclevcn.com,DNS.5:*.oraclevcn.com,DNS.6:siebel23
rmdir %KEYMAKER_HOME%\%ALIAS%
mkdir %KEYMAKER_HOME%\%ALIAS%

%JAVA%\keytool -genkey -alias %ALIAS% -keystore %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.jks -keyalg RSA -sigalg SHA256withRSA -dname "cn=%FQDN%" -storepass %PASSWORD% -keypass %PASSWORD%
%JAVA%\keytool -list -v -keystore %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD%
%JAVA%\keytool -certreq -alias %ALIAS% -keystore %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.jks -file %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.csr -storepass %PASSWORD% -keypass %PASSWORD%
%SSL%/openssl req -newkey rsa:2048 -keyout %KEYMAKER_HOME%\%ALIAS%\cakey.pem -out %KEYMAKER_HOME%\%ALIAS%\careq.pem -subj "/CN=%CANAME%" -sha256 -passout pass:%PASSWORD%
%SSL%\openssl x509 -signkey %KEYMAKER_HOME%\%ALIAS%\cakey.pem -req -days 3650 -in %KEYMAKER_HOME%\%ALIAS%\careq.pem -out %KEYMAKER_HOME%\%ALIAS%\caroot.cer -extfile v3.txt -passin pass:%PASSWORD%
%JAVA%\keytool -printcert -v -file %KEYMAKER_HOME%\%ALIAS%\caroot.cer
echo basicConstraints=CA:FALSE>> %KEYMAKER_HOME%\%ALIAS%\ext.cnf
echo subjectAltName=DNS.1:%FQDN%%SAN%>> %KEYMAKER_HOME%\%ALIAS%\ext.cnf
echo extendedKeyUsage=serverAuth,clientAuth>> %KEYMAKER_HOME%\%ALIAS%\ext.cnf
rem copy ext.cnf %KEYMAKER_HOME%\%ALIAS%\ext.cnf
echo 1234 > %KEYMAKER_HOME%\%ALIAS%\serial.txt
%SSL%\openssl x509 -CA %KEYMAKER_HOME%\%ALIAS%\caroot.cer -CAkey %KEYMAKER_HOME%\%ALIAS%\cakey.pem -CAserial %KEYMAKER_HOME%\%ALIAS%\serial.txt -req -in %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.csr -out %KEYMAKER_HOME%\%ALIAS%\siebelkeystoreCASigned.cer -days 3650 -extfile %KEYMAKER_HOME%\%ALIAS%\ext.cnf -passin pass:%PASSWORD%
%JAVA%\keytool -import -alias %ALIAS%ca -file %KEYMAKER_HOME%\%ALIAS%\caroot.cer -keystore %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
%JAVA%\keytool -import -alias %ALIAS% -file %KEYMAKER_HOME%\%ALIAS%\siebelkeystoreCASigned.cer -keystore %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD%
%JAVA%\keytool -list -v -keystore %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD%
echo Use the following path for both keystore and truststore in all Siebel installations: %KEYMAKER_HOME%\%ALIAS%\siebelkeystore.jks
echo Use the following password for both keystore and truststore: %PASSWORD%
echo %PASSWORD%>> %KEYMAKER_HOME%\%ALIAS%\password.txt
rem uncomment below to create truststore
rem %JAVA%\keytool -import -alias %ALIAS% -file %KEYMAKER_HOME%\%FQDN%\siebelkeystoreCASigned.cer -keystore %KEYMAKER_HOME%\siebeltruststore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
rem %JAVA%\keytool -import -alias %ALIAS%ca -file %KEYMAKER_HOME%\%FQDN%\caroot.cer -keystore %KEYMAKER_HOME%\siebeltruststore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
