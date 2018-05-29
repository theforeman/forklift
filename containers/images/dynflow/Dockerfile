FROM quay.io/foreman/foreman:latest

COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/wait_on_migrations.py /usr/bin/wait_on_migrations.py

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["/usr/sbin/dynflowd", "--foreman-root=/usr/share/foreman", "run"]
