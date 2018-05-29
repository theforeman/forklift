FROM centos:7

COPY container-assets/pulp.repo /etc/yum.repos.d/pulp.repo

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm && \
		yum -y install pulp-server python-qpid python-qpid-qmf qpid-tools python-gofer-qpid && \
		yum -y install pulp-rpm-plugins pulp-puppet-plugins pulp-docker-plugins pulp-katello && \
		yum clean all

RUN pulp-gen-ca-certificate
RUN pulp-gen-key-pair

RUN rm /etc/pki/tls/certs/localhost.crt
RUN rm /etc/pki/tls/private/localhost.key

RUN ln -s /etc/pki/pulp/certs/pulp.crt /etc/pki/tls/certs/localhost.crt
RUN ln -s /etc/pki/pulp/private/pulp.key /etc/pki/tls/private/localhost.key
RUN rm /etc/pki/pulp/ca.crt -f && ln -s /etc/pki/pulp/certs/ca.crt /etc/pki/pulp/ca.crt
RUN rm /etc/pki/pulp/ca.key -f && ln -s /etc/pki/pulp/private/ca.key /etc/pki/pulp/ca.key

RUN usermod -g root apache

COPY container-assets/server.conf /etc/pulp/server.conf
COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/wait_on_mongodb.py /usr/bin/wait_on_mongodb.py
COPY container-assets/migrate_database.py /usr/bin/migrate_database.py
COPY container-assets/wait_on_database_migration.py /usr/bin/wait_on_database_migration.py
COPY container-assets/ssl_username.conf /etc/httpd/conf.d/ssl_username.conf

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]
