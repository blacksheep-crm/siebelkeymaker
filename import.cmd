@echo off
rem usage: import target_fqdn source_fqdn source_alias
set TARGETFQDN=%1
set SOURCEFQDN=%2
set SOURCEALIAS=%3
set JAVA=C:\JDK\bin
set SSL=C:\OpenSSL\bin
set SIEBEL=C:\keymaker
set PASSWORD=siebel

rem DO NOT CHANGE
set OPENSSL_CONF=%SSL%\openssl.cfg

%JAVA%\keytool -import -alias %SOURCEALIAS% -file %SIEBEL%\%SOURCEFQDN%\siebelkeystoreCASigned.cer -keystore %SIEBEL%\%TARGETFQDN%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
%JAVA%\keytool -import -alias %SOURCEALIAS%ca -file %SIEBEL%\%SOURCEFQDN%\caroot.cer -keystore %SIEBEL%\%TARGETFQDN%\siebelkeystore.jks -storepass %PASSWORD% -keypass %PASSWORD% -noprompt
