FROM centos:7

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
		yum -y install squid && \
		yum clean all

COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/squid.conf /etc/squid/squid.conf

CMD ["/usr/sbin/squid", "-f", "/etc/squid/squid.conf", "-NCd", "1"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
