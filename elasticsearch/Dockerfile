FROM docker.elastic.co/elasticsearch/elasticsearch:8.11.1

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu
RUN mkdir /usr/share/elasticsearch/config/certs

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
