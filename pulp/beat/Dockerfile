FROM pulp/base:latest
MAINTAINER Pulp Team <pulp-list@redhat.com>

ADD run.sh /run.sh
RUN mkdir /var/lib/pulp/celery
RUN chmod 777 /var/lib/pulp/celery

ENTRYPOINT ["/run.sh"]
