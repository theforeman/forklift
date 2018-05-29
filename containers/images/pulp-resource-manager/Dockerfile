FROM quay.io/foreman/pulp:latest

RUN mkdir /var/lib/pulp/celery
RUN chmod 0777 /var/lib/pulp/celery

COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_pulp_resource_manager.sh /usr/bin/start_pulp_resource_manager.sh

USER apache

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/usr/bin/start_pulp_resource_manager.sh"]
