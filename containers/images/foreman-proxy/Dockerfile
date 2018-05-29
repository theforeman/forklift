FROM centos:7

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
    yum -y install http://yum.theforeman.org/releases/nightly/el7/x86_64/foreman-release.rpm && \
    yum -y install foreman-release-scl && \
    yum -y install foreman-proxy && \
    yum -y install rubygem-smart_proxy_pulp rubygem-smart_proxy_remote_execution_ssh rubygem-smart_proxy_discovery rubygem-smart_proxy_ansible rubygem-smart_proxy_openscap && \
    yum clean all

COPY container-assets/logs.yml /etc/foreman-proxy/settings.d/logs.yml
COPY container-assets/pulp.yml /etc/foreman-proxy/settings.d/pulp.yml
COPY container-assets/puppet.yml /etc/foreman-proxy/settings.d/puppet.yml
COPY container-assets/puppet_proxy_puppet_api.yml /etc/foreman-proxy/settings.d/puppet_proxy_puppet_api.yml
COPY container-assets/settings.yml /etc/foreman-proxy/settings.yml
COPY container-assets/register.sh /usr/bin/register.sh

RUN ln -s /etc/foreman-proxy/settings.d /usr/share/foreman-proxy/config/settings.d

CMD ["/usr/share/foreman-proxy/bin/smart-proxy"]
