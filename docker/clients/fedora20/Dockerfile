FROM fedora:20
MAINTAINER Katello Team <foreman-dev@googlegroups.com>

RUN yum clean all
RUN yum update -y && yum -y install subscription-manager

ADD run.sh /run.sh

CMD ["/run.sh"]
