FROM centos:centos5
MAINTAINER Katello Team <foreman-dev@googlegroups.com>

RUN yum install -y epel-release && yum clean all
RUN yum update -y && yum -y install wget

ADD run.sh /run.sh

CMD ["/run.sh"]
