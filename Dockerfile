# This is a base image that 3.11 APB containers should layer on.
FROM ansible-runner:1.2.0
# ansible-runner-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=67496)

RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
