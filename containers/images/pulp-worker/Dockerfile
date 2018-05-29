FROM quay.io/foreman/pulp:latest

COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_pulp_worker.sh /usr/bin/start_pulp_worker.sh

USER apache

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/usr/bin/start_pulp_worker.sh"]
