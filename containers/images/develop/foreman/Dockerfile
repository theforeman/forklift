FROM fedora:27

ARG hostUID

RUN mkdir -p /usr/src/app && \
    dnf -y install ruby{,-devel,gems} rubygem-{nokogiri,bundler,unf_ext,rdoc} \
                   libvirt-devel mysql-devel postgresql-devel sqlite-devel \
                   libxml2-devel libcurl-devel systemd-devel \
                   redhat-rpm-config nodejs git gcc-c++ make hostname && \
    dnf -y clean all

WORKDIR /usr/src/app

VOLUME [ "/usr/src/app", "/usr/local/share/gems", "/usr/local/bin" ]

RUN useradd --uid ${hostUID} -m foremanuser
