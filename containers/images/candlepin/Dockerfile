FROM centos:7

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
    yum -y install https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm && \
    yum -y install candlepin openssl qpid-tools && \
    yum clean all

COPY container-assets/candlepin.conf /etc/candlepin/candlepin.conf
COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_candlepin.sh /usr/bin/start_candlepin.sh
COPY container-assets/wait_on_postgres.py /usr/bin/wait_on_postgres.py
COPY container-assets/gen-certs /usr/bin/gen-certs

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/usr/bin/start_candlepin.sh"]
