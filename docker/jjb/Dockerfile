FROM centos:centos7
MAINTAINER Katello Team <foreman-dev@googlegroups.com>

RUN yum install -y epel-release && yum clean all
RUN yum install -y git python-pip vim

RUN pip install virtualenv

RUN git clone https://github.com/theforeman/jenkins-job-builder.git -b local
RUN cd jenkins-job-builder
RUN virtualenv jjb
RUN source jjb/bin/activate
RUN easy_install .
