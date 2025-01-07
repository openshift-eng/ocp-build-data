# This is a base image for supporting a ruby app that runs on it.
# The same Dockerfile should serve for most versions of ruby.
FROM ruby
# rhscl/ruby-25-rhel7 from rh-ruby25-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=66958)
# ubi8/ruby from ruby-25-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=69970)

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1001
