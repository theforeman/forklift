FROM centos:7

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
    yum -y install http://yum.theforeman.org/nightly/el7/x86_64/foreman-release.rpm && \
    yum -y install foreman-release-scl && \
    yum -y install https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm && \
    yum -y install ansible curl ruby git yum-utils sos bats && \
    yum -y install tfm-rubygem-hammer_cli_katello

WORKDIR /root

COPY container-assets/bats.yml /root/bats.yml
COPY container-assets/container.bats /root/container.bats
COPY container-assets/run-tests.sh /usr/bin/run-tests.sh

RUN chmod +x /usr/bin/run-tests.sh

RUN echo ":verify_ssl: false" >> /etc/hammer/cli_config.yml
RUN sed -i "s|#:password: 'example'|:password: changeme|g" /etc/hammer/cli.modules.d/foreman.yml

RUN git clone https://github.com/theforeman/forklift

CMD ["/usr/bin/run-tests.sh"]
