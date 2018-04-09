FROM centos:7

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
    yum -y install nss_wrapper rsync openssh-clients

COPY container-assets/entrypoint /entrypoint
COPY container-assets/nss_wrapper /nss_wrapper

CMD ["/entrypoint"]
