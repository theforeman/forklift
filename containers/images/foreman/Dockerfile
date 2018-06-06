FROM centos:7

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release \
                   http://yum.theforeman.org/releases/nightly/el7/x86_64/foreman-release.rpm \
                   https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm && \
    yum -y install foreman-release-scl && \
    yum -y install qpid-tools ansible && \
    yum -y install foreman tfm-rubygem-puma \
                   tfm-rubygem-katello tfm-rubygem-foreman_ansible tfm-rubygem-foreman_discovery tfm-rubygem-foreman_hooks \
                   tfm-rubygem-foreman_openscap tfm-rubygem-foreman_remote_execution tfm-rubygem-foreman_templates && \
    yum clean all

COPY container-assets/settings.yaml /etc/foreman/settings.yaml
COPY container-assets/katello.yaml /etc/foreman/plugins/katello.yaml

# Generate apipie:cache:index
RUN yum -y install foreman-sqlite && \
    yum clean all

RUN DATABASE_URL=sqlite3::memory: foreman-rake db:create db:migrate apipie:cache:index

RUN yum -y remove foreman-sqlite tfm-ror51-rubygem-sqlite3 && \
    yum clean all
# end generate apipie:cache:index

RUN yum -y install tfm-rubygem-foreman_memcache && \
    yum clean all

COPY container-assets/foreman_memcache.yaml /etc/foreman/plugins/foreman_memcache.yaml
COPY container-assets/database.yml /etc/foreman/database.yml
COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_foreman.sh /usr/bin/start_foreman.sh
COPY container-assets/wait_on_postgres.py /usr/bin/wait_on_postgres.py

COPY container-assets/create_qpid_queue.yml /root/playbooks/create_qpid_queue.yml

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/usr/bin/start_foreman.sh"]
