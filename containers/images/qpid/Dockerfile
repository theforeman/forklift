FROM centos:7

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
    yum -y install qpid-cpp-server python-qpid-qmf python-qpid && \
    yum clean all

EXPOSE 5672

CMD ["qpidd", "--auth=no", "-p", "5672"]
