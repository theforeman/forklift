FROM pulp/crane:latest

MAINTAINER Pulp Team <pulp-list@redhat.com>

ADD crane.conf /etc/crane.conf

ENTRYPOINT ["/usr/sbin/httpd"]
CMD ["-D", "FOREGROUND"]
