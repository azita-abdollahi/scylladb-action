FROM docker:stable
COPY start-scylladb.sh /start-scylladb.sh
ENTRYPOINT ["/start-scylladb.sh"]