FROM fedora:latest
#RUN dnf -y upgrade
RUN dnf install -y hostname facter
RUN dnf clean all
ADD upload_facts.rb upload_facts.rb
ENV FOREMAN_URL=http://foreman:3000

CMD ["./upload_facts.rb"]
