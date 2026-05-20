#!/bin/bash

if [ -f /usr/share/elasticsearch/config/certs/ca.p12 ] && [ -f /usr/share/elasticsearch/config/certs/elastic-certificates.p12 ]; then
  echo '✓ Certificates exist'
else
  echo 'Generating certificates...'
  elasticsearch-certutil ca --out /usr/share/elasticsearch/config/certs/ca.p12 --pass ''
  elasticsearch-certutil cert --name elasticsearch-dina --ca /usr/share/elasticsearch/config/certs/ca.p12 --ca-pass '' --out /usr/share/elasticsearch/config/certs/elastic-certificates.p12 --pass ''
  echo '✓ Done'
fi

# Call the original entrypoint
/usr/local/bin/docker-entrypoint.sh eswrapper
