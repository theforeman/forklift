# This runs crane (http://github.com/pulp/crane) on centos
#
# Example usage:
# $ sudo docker run -p 5000:80 -v /home/you/cranedata:/var/lib/crane/metadata pulp/crane

FROM centos:centos7
MAINTAINER Pulp Team <pulp-list@redhat.com>

ADD rhel-pulp.repo /etc/yum.repos.d/rhel-pulp.repo

RUN yum install -y epel-release && yum clean all

RUN yum update -y && yum install -y python-crane httpd mod_wsgi && yum clean all

RUN ln -s /usr/share/crane/apache.conf /etc/httpd/conf.d/crane.conf

ENV APACHE_RUN_USER apache
ENV APACHE_RUN_GROUP apache

EXPOSE 80

ENTRYPOINT ["/usr/sbin/httpd"]
CMD ["-D", "FOREGROUND"]
