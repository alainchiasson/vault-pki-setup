FROM centos

WORKDIR /workdir

RUN yum install -y yum-utils 
RUN yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

RUN yum -y install vault

RUN yum install -y libcap which unzip jq
RUN setcap cap_ipc_lock= /usr/bin/vault

# Copy shell scripts to setup.
COPY scripts/* /usr/local/sbin

# Set command line to wait for login.
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"

