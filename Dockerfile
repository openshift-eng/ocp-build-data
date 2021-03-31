# This is a base image that most rhel8-based containers should layer on.
FROM rhel8
# generally we prefer ubi8 as a base for redistributability, but there is no ELS UBI 8.2 stream.
# rhel8-2-els/rhel from rhel-els-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=77439)
# ubi8 from ubi8-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=71187)

RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
