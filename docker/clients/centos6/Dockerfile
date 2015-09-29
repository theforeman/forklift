FROM centos:centos6
MAINTAINER Katello Team <foreman-dev@googlegroups.com>

RUN yum install -y epel-release && yum clean all
RUN yum install -y wget
RUN wget https://copr.fedoraproject.org/coprs/dgoodwin/subscription-manager/repo/epel-6/dgoodwin-subscription-manager-epel-6.repo -O /etc/yum.repos.d/dgoodwin-subscription-manager-epel-6.repo
RUN yum update -y && yum -y install subscription-manager

ADD run.sh /run.sh

CMD ["/run.sh"]
