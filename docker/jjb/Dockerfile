FROM centos:centos7
MAINTAINER Katello Team <foreman-dev@googlegroups.com>

RUN yum install -y epel-release && yum clean all
RUN yum install -y git python-pip vim

RUN pip install virtualenv

RUN pip install jenkins_job_builder
