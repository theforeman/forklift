FROM quay.io/water-hole/ansible-operator

RUN echo "retry_files_enabled = false" >> /etc/ansible/ansible.cfg

RUN adduser foreman-operator
USER foreman-operator

COPY roles/ /opt/ansible/roles/
COPY playbook.yaml /opt/ansible/roles/playbook.yaml
COPY config.yaml /opt/ansible/config.yaml
