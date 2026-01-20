FROM docker.elastic.co/elasticsearch/elasticsearch:8.11.1

RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install analysis-icu

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
