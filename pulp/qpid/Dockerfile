FROM centos:centos7
MAINTAINER Pulp Team <pulp-list@redhat.com>

RUN yum install -y epel-release && yum clean all

RUN  yum update -y && \
     yum install -y qpid-cpp-server python-qpid-qmf python-qpid \
     yum clean all

EXPOSE 5672

ENTRYPOINT ["qpidd", "--auth=no"]
