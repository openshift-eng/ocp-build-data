# This image is used to support cassandra in 3.11
FROM jboss/openjdk18-rhel7:latest
# jboss-openjdk18-rhel7-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=66550)

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 185
