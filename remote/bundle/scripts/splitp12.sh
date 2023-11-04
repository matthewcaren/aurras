#!/bin/sh

if [ ! $# -eq 2 ]; then
	echo "usage: $0 <.p12 file> <import password>"
	exit 1
fi

cert="`basename $1 .p12`.pem"
key="`basename $1 .p12`.key"

openssl pkcs12 -in $1 -nocerts -nodes -passin pass:$2 -out $key 2>/dev/null
openssl pkcs12 -in $1 -nokeys -passin pass:$2 -out $cert 2>/dev/null
