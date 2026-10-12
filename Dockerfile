# This is a base image that most rhel8-based containers should layer on.
FROM rhel8
# generally we prefer ubi8 as a base for redistributability, but there is no ELS UBI 8.2 stream.
# rhel8-2-els/rhel from rhel-els-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=77439)
# ubi8 from ubi8-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=71187)

# If we are build atop UBI or ELS minimal image, setup a link so that invocations of
# dnf and yum call microdnf instead.
COPY microdnf-wrapper.sh /usr/bin/microdnf-wrapper.sh
RUN chmod +x /usr/bin/microdnf-wrapper.sh
RUN if [ -x /usr/bin/microdnf ]; then \
      echo "microdnf detected: creating symlinks for dnf and yum"; \
      ln -sf /usr/bin/microdnf-wrapper.sh /usr/bin/dnf || true; \
      ln -sf /usr/bin/microdnf-wrapper.sh /usr/bin/yum || true; \
    else \
      echo "microdnf not found: skipping dnf/yum symlink creation"; \
    fi

RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all

# ubi based images have the ubi repositories available. EUS / ELS images do not have their repositories
# configured, and these repositories are not publicly accessible without an enabled subscription.
# Making ubi8 repo available for all base images for the end user.
COPY ubi.repo /etc/yum.repos.d/ubi.repo
