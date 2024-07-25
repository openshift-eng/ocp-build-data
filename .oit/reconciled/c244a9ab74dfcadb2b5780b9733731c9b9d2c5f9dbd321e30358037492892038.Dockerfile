# This is a base image that most rhel9-based containers should layer on.
FROM rhel9
# we pin to a RHEL EUS (rhel-els) stream for stability.
# rhel9-els from rhel-els-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=77439)

RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all

# EUS / ELS images do not have repositories configured, and anyway they would
# not be publicly accessible without an enabled subscription. Insert public
# ubi9 repos in the base image so the end user can update all images easily.
COPY ubi.repo /etc/yum.repos.d/ubi.repo
