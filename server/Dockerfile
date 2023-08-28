FROM python

WORKDIR /workdir

RUN apt-get update && apt-get install -y lsb-release software-properties-common gpg jq
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |  tee /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install -y vault

RUN setcap cap_ipc_lock= /usr/bin/vault

COPY python/requirements.txt .

RUN pip install -r requirements.txt
RUN rm requirements.txt

COPY python/* /usr/local/bin

# Copy shell scripts to setup.
COPY scripts/* /usr/local/sbin

# Set command line to wait for login.
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"

