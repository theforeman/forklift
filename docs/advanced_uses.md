# Advanced Uses

This section covers advanced ways that you can use what Forklift provides.

## Topologies

Similar to the way the pipelines are built for testing, a collection of systems can be defined as well as what goes on to each system in a single playbook. You can then ask Ansible to run and bring up each system with what you need on it and potentially connected to one another. Let's look at a concrete example. The basic multi-system setup is a server running Foreman and Katello, an external Foreman Proxy and a client machine configured through the Foreman Proxy for isolation. Thus, we need three systems with the Proxy talking to the server and the client talking to the proxy. We can achieve this with the following playbook:

```
- hosts: localhost
  vars:
    forklift_name: nightly-server-proxy-client
    forklift_boxes:
      server-nightly-centos7:
        box: centos7
        memory: 4680
      proxy-nightly-centos7:
        box: centos7
        memory: 3072
      client-nightly-centos7:
        box: centos7
        memory: 3072
  roles:
    - forklift

- hosts: server-nightly-centos7
  become: yes
  vars:
    puppet_repositories_version: 4
    katello_repositories_version: nightly
    foreman_repositories_version: nightly
    katello_repositories_use_koji: true
    foreman_installer_scenario: katello
    foreman_installer_options_internal_use_only:
      - "--disable-system-checks"
      - "--foreman-admin-password {{ foreman_installer_admin_password }}"
    foreman_installer_additional_packages:
      - katello
  roles:
    - selinux
    - etc_hosts
    - epel_repositories
    - puppet_repositories
    - foreman_repositories
    - katello_repositories
    - foreman_installer

- hosts: proxy-nightly-centos7
  become: yes
  vars:
    puppet_repositories_version: 4
    foreman_proxy_content_server: server-nightly-centos7
    katello_repositories_version: nightly
    foreman_repositories_version: nightly
    katello_repositories_use_koji: true
    foreman_installer_scenario: foreman-proxy-content
    foreman_installer_options_internal_use_only:
      - '--disable-system-checks
        --foreman-proxy-trusted-hosts "{{ server_fqdn.stdout }}"
        --foreman-proxy-trusted-hosts "{{ ansible_nodename }}"
        --foreman-proxy-foreman-base-url "https://{{ server_fqdn.stdout }}"
        --foreman-proxy-register-in-foreman true
        --foreman-proxy-oauth-consumer-key "{{ oauth_consumer_key.stdout }}"
        --foreman-proxy-oauth-consumer-secret "{{ oauth_consumer_secret.stdout }}"
        --foreman-proxy-content-certs-tar "{{ foreman_proxy_content_certs_tar }}"
        --foreman-proxy-content-parent-fqdn "{{ server_fqdn.stdout }}"
        --foreman-proxy-content-pulp-oauth-secret "{{ pulp_oauth_secret.stdout }}"'
    foreman_installer_additional_packages:
      - foreman-installer-katello
  roles:
    - selinux
    - etc_hosts
    - epel_repositories
    - puppet_repositories
    - foreman_repositories
    - katello_repositories
    - foreman_proxy_content
    - foreman_installer

- hosts: client-nightly-centos7
  become: yes
  vars:
    katello_client_server: "proxy-nightly-centos7.example.com"
  roles:
    - etc_hosts
    - epel_repositories
    - katello_client_repositories
    - katello_client
```

The same could be done to bring up infrastructure against a development environment or to create large sets of Proxies and/or clients for testing. Those are left as exercises for the reader to achieve their own needs.
