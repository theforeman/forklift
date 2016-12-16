FROM pulp/base:latest
MAINTAINER Pulp Team <pulp-list@redhat.com>

EXPOSE 80 443

ADD run.sh /run.sh

# we make the images available on port 80 for this non-secure demo, so docker
# won't complain about SSL validation during "docker pull"
ADD docker.conf /etc/pulp/vhosts80/docker.conf
RUN rm /etc/httpd/conf.d/pulp_docker.conf
ADD pulp_docker.conf /etc/httpd/conf.d/pulp_docker.conf

CMD [ "/run.sh" ]
