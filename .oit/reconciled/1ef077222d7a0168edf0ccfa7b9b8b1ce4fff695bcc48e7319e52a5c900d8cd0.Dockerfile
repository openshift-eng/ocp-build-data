# This is a base image that most rhel10-based containers should layer on.
FROM rhel10
# we pin to a RHEL EUS (rhel-els) stream for stability.
# rhel10-els from rhel-els-container

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

# EUS / ELS images do not have repositories configured, and anyway they would
# not be publicly accessible without an enabled subscription. Insert public
# ubi10 repos in the base image so the end user can update all images easily.
COPY ubi.repo /etc/yum.repos.d/ubi.repo
