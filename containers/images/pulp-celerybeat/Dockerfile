FROM quay.io/foreman/pulp:latest

COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_pulp_celerybeat.sh /usr/bin/start_pulp_celerybeat.sh

USER apache

CMD ["/usr/bin/start_pulp_celerybeat.sh"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
