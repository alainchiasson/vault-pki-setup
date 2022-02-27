FROM python

WORKDIR /workdir

RUN apt-get update && apt-get install -y lsb-release software-properties-common
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-get update && apt-get install -y vault jq

RUN setcap cap_ipc_lock= /usr/bin/vault

# No python yet
# COPY python/requirements.txt .

# RUN pip install -r requirements.txt
# RUN rm requirements.txt

# COPY python/* /usr/local/bin

# Copy shell scripts to setup.
COPY scripts/* /usr/local/sbin

# Set command line to wait for login.
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"

