#!/bin/bash

if [ -f /usr/share/elasticsearch/config/certs/ca/ca.crt ] && [ -f /usr/share/elasticsearch/config/certs/elastic-node-certificates.p12 ]; then
  echo '✓ Certificates exist'
else
  echo 'Generating certificates...'
  elasticsearch-certutil ca --pem --days 3650 --out /usr/share/elasticsearch/config/certs/elastic-ca.zip
  unzip -d /usr/share/elasticsearch/config/certs /usr/share/elasticsearch/config/certs/elastic-ca.zip
  
  elasticsearch-certutil cert --name elastic-certs --ca-cert /usr/share/elasticsearch/config/certs/ca/ca.crt --ca-key /usr/share/elasticsearch/config/certs/ca/ca.key --pem --dns 'elasticsearch-dina' --days 3650 --out /usr/share/elasticsearch/config/certs/elastic-certs.zip

  elasticsearch-certutil cert --name elasticsearch-node-dina --ca-cert /usr/share/elasticsearch/config/certs/ca/ca.crt --ca-key /usr/share/elasticsearch/config/certs/ca/ca.key --out /usr/share/elasticsearch/config/certs/elastic-node-certificates.p12 --pass ''
  
  unzip -d /usr/share/elasticsearch/config/certs /usr/share/elasticsearch/config/certs/elastic-certs.zip
  echo '✓ Done'
fi

# Call the original entrypoint
/usr/local/bin/docker-entrypoint.sh eswrapper
