# This is a base image that most rhel7-based containers should layer on.
FROM registry.redhat.io/rhel7:latest
# ^ latest rhel 7 https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=67330

RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
