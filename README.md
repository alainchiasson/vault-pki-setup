# Vault PKI with Approle templates.

The goal here is to create a pki infrastructure in Vault for mTLS and demonstrate the power of policy templates with the auth engines. In this case, we are using the Approle entity metadata as the link to a pki policy of the same name. In doing this, we have a single policy which can be used by multiple applications, each identified by an Approle - allowing them to self manage TLS certificates.

# Startup 

To start, launch docker compose. 

    docker compose up -d --build

Our docker composes uses Hashicorp's vault container. It is started up with the root key as "root" to simplify the initial setup. Currently We use root for all activities, except for the generation of the certificates and keys for the mTLS endpoints - where we use the Approles and policies, which is what we are demonstrating.

# Initial provisioning 

The shell container has the initial provisioing script : 

    docker compose exec shell /bin/bash -c setup_pki.sh

This will create all required endpoints ( pki_root, pki_int, approle), it creates the policy to link approle name to pki_int/rolename, and then creates 2 Approles and PKI\role. 

# Launching the server

The server is a basic python application that listens for a TLS connection, establishes the mTLS connection and prints out the received client certififcate information ( CommonName ). To get the required information, you run the 'get_cert.sh' script, followed by the server.py script. The get_certs.sh will generate role_id and secrets_id, then login with the server approle and get a certificate. It also downloads the Certificate chain to build the trust store.

    docker compose exec server /bin/bash -c get_cert.sh
    docker compose exec server /bin/bash -c server.py

# Launching the client

The client is a basic python application that connects to a server, establishes the mTLS connection and prints out the received server certififcate information ( CommonName ). To get the required information, you run the 'get_cert.sh' script, followed by the server.py script. The get_certs.sh will generate role_id and secrets_id, then login with the server approle and get a certificate. It also downloads the Certificate chain to build the trust store.

    docker compose exec client /bin/bash -c get_cert.sh
    docker compose exec client /bin/bash -c client.py

# Further directions

while the application does demonstrate everything required, there are other directions that we can go.

## Client Authorisation

While the connection is considered secured, any cllient with a certificate signed by something in the trust store will be able to connect. THe Common Name, considered secured, can now be used to discriminate between different clients (this is what etcd uses). Different hieriarchy points can also be used - either discriminate via the root server, or have a seperate intermediate certificate ( and chain). 

## Additional auth links.

In this case we are maiking the link between Approle and PkiRole name. We can explore other links between applications.

# Trouble shooting 

Some usfull commands : 

    openssl verify -CAfile chain.pem www.example.org.pem

Another usefull link - common opensslo commands.

    https://www.sslshopper.com/article-most-common-openssl-commands.html

## TODO:

- rotate certificates
- initial creation of next int
- rotate by update or rotate by new endpoint.
