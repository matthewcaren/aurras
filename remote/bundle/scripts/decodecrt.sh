#!/bin/sh

if [ ! $# -eq 1 ]; then
	echo "usage: $0 <path to mitca.crt>"
	exit 1
fi

outfile=`basename $1 .crt`.pem

openssl x509 -inform DER -in $1 -outform PEM -out $outfile
