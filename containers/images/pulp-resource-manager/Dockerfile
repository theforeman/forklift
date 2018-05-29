FROM quay.io/foreman/pulp:latest

RUN mkdir /var/lib/pulp/celery
RUN chmod 0777 /var/lib/pulp/celery

COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_celery_beat.sh /usr/bin/start_celery_beat.sh

USER apache

CMD ["/usr/bin/start_celery_beat.sh"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
