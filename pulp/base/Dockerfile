FROM centos:7

RUN yum -y install https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm

RUN yum install -y epel-release
RUN yum clean all
RUN yum update -y
RUN yum install -y python-qpid python-qpid-qmf findutils nmap-ncat qpid-tools python-gofer-qpid pulp-server
RUN yum install -y pulp-rpm-plugins pulp-puppet-plugins pulp-docker-plugins pulp-katello
RUN yum clean all

RUN yum -y install wget
RUN wget -O /usr/lib/python2.7/site-packages/pulp/server/logs.py https://raw.githubusercontent.com/ehelms/pulp/log-to-file/server/pulp/server/logs.py

ADD server.conf /etc/pulp/server.conf
RUN chgrp apache /etc/pulp/server.conf
