@echo off
rem usage: make fqdn alias
set ALIAS=%2
set FQDN=%1
rem set SANs example below, remove comment to use and replace "echo subjectAltName..."
set SAN=,DNS.2:another-machine.subnet.vcn.oraclevcn.com,DNS.3:*.subnet.vcn.oraclevcn.com,DNS.4:*.oraclevcn.com
rem CHANGE_ME! :)
set JAVA=C:\JDK\bin
set SSL=C:\OpenSSL\bin
set SIEBEL=C:\keymaker
set PASSWORD=siebel

rem DO NOT CHANGE
set OPENSSL_CONF=%SSL%\openssl.cfg
rem set SAN=DNS.1:%FQDN%
rmdir /S /Q %SIEBEL%\%FQDN%
mkdir %SIEBEL%\%FQDN%

%JAVA%\keytool -genkey -alias %ALIAS% -keystore %SIEBEL%\%FQDN%\siebelkeystore.jks -keyalg RSA -sigalg SHA256withRSA -dname "cn=%FQDN%" -storepass %PASSWORD% -keypass %PASSWORD% -storetype JKS
%JAVA%\keytool -list -v -keystore %SIEBEL%\%FQDN%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD%
%JAVA%\keytool -certreq -alias %ALIAS% -keystore %SIEBEL%\%FQDN%\siebelkeystore.jks -file %SIEBEL%\%FQDN%\siebelkeystore.csr -storepass %PASSWORD% -keypass %PASSWORD%
%SSL%\openssl req -newkey rsa:2048 -keyout %SIEBEL%\%FQDN%\cakey.pem -out %SIEBEL%\%FQDN%\careq.pem -subj "/CN=%FQDN%" -sha256 -passout pass:%PASSWORD%
%SSL%\openssl x509 -signkey %SIEBEL%\%FQDN%\cakey.pem -req -days 3650 -in %SIEBEL%\%FQDN%\careq.pem -out %SIEBEL%\%FQDN%\caroot.cer -extfile v3.txt -passin pass:%PASSWORD%
%JAVA%\keytool -printcert -v -file %SIEBEL%\%FQDN%\caroot.cer
echo basicConstraints=CA:FALSE>> %SIEBEL%\%FQDN%\ext.cnf
rem echo subjectAltName=DNS.1:%FQDN%>> %SIEBEL%\%FQDN%\ext.cnf
rem set SANs example
echo subjectAltName=DNS.1:%FQDN%%SAN%>> %SIEBEL%\%FQDN%\ext.cnf
echo extendedKeyUsage=serverAuth,clientAuth>> %SIEBEL%\%FQDN%\ext.cnf
rem copy ext.cnf %SIEBEL%\%FQDN%\ext.cnf
echo 1234 > %SIEBEL%\%FQDN%\serial.txt
%SSL%\openssl x509 -CA %SIEBEL%\%FQDN%\caroot.cer -CAkey %SIEBEL%\%FQDN%\cakey.pem -CAserial %SIEBEL%\%FQDN%\serial.txt -req -in %SIEBEL%\%FQDN%\siebelkeystore.csr -out %SIEBEL%\%FQDN%\siebelkeystoreCASigned.cer -days 3650 -extfile %SIEBEL%\%FQDN%\ext.cnf -passin pass:%PASSWORD%
%JAVA%\keytool -import -alias %ALIAS%ca -file %SIEBEL%\%FQDN%\caroot.cer -keystore %SIEBEL%\%FQDN%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
%JAVA%\keytool -import -alias %ALIAS% -file %SIEBEL%\%FQDN%\siebelkeystoreCASigned.cer -keystore %SIEBEL%\%FQDN%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD%
%JAVA%\keytool -list -v -keystore %SIEBEL%\%FQDN%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD%
echo Use the following path for both keystore and truststore in all Siebel installations: %SIEBEL%\%FQDN%\siebelkeystore.jks
echo Use the following password for both keystore and truststore: %PASSWORD%
rem uncomment below to create truststore
rem %JAVA%\keytool -import -alias %ALIAS% -file %SIEBEL%\%FQDN%\siebelkeystoreCASigned.cer -keystore %SIEBEL%\siebeltruststore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
rem %JAVA%\keytool -import -alias %ALIAS%ca -file %SIEBEL%\%FQDN%\caroot.cer -keystore %SIEBEL%\siebeltruststore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
