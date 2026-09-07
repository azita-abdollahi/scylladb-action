FROM docker:stable

COPY start-scylladb.sh cleanup.sh /
RUN chmod +x /start-scylladb.sh /cleanup.sh

ENTRYPOINT ["/start-scylladb.sh"]