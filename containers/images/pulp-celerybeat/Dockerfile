FROM quay.io/foreman/pulp:latest

COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_pulp_celerybeat.sh /usr/bin/start_pulp_celerybeat.sh

RUN mkdir /var/lib/pulp/celery
RUN chmod 0777 /var/lib/pulp/celery

USER apache

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/usr/bin/start_pulp_celerybeat.sh"]
