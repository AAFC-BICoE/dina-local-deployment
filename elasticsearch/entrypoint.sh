#!/bin/bash

if [ -f /usr/share/elasticsearch/config/certs/ca.crt ] && [ -f /usr/share/elasticsearch/config/certs/elastic-certificates.p12 ]; then
  echo '✓ Certificates exist'
else
  echo 'Generating certificates...'
  elasticsearch-certutil ca --out /usr/share/elasticsearch/config/certs/ca.crt --pass ''
  elasticsearch-certutil cert --ca /usr/share/elasticsearch/config/certs/ca.crt --ca-pass '' --out /usr/share/elasticsearch/config/certs/elastic-certificates.p12 --pass ''
  chmod 644 /usr/share/elasticsearch/config/certs/*
  echo '✓ Done'
fi

# Call the original entrypoint
/usr/local/bin/docker-entrypoint.sh eswrapper
