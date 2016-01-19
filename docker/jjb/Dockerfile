FROM centos:centos7
MAINTAINER Katello Team <foreman-dev@googlegroups.com>

RUN yum install -y epel-release && yum clean all
RUN yum install -y git python-pip vim

RUN pip install virtualenv

RUN git clone https://github.com/theforeman/jenkins-job-builder.git
RUN git config --global user.name test
RUN git config --global user.email test@test.test

WORKDIR jenkins-job-builder
RUN git checkout local
RUN git remote add openstack https://github.com/openstack-infra/jenkins-job-builder.git
RUN git fetch openstack
RUN git merge 1.4.0

RUN virtualenv jjb
RUN source jjb/bin/activate
RUN easy_install .
