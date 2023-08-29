# Vault PKI with Approle templates.

The goal here is to create a pki infrastructure in Vault for mTLS and demonstrate the power of policy templates with the auth engines. In this case, we are using the Approle entity metadata as the link to a pki policy of the same name. In doing this, we have a single policy which can be used by multiple applications, each identified by an Approle - allowing them to self manage TLS certificates.

Also, it allows us to demonstrate Issuing certificate rotation, and one way to get around the challeges in vault.

# Startup 

To start, launch docker compose. 

    docker compose up -d --build

Our docker composes uses Hashicorp's vault container. It is started up with the root key as "root" to simplify the initial setup. Currently We use root for all activities, except for the generation of the certificates and keys for the mTLS endpoints - where we use the Approles and policies, which is one item we are demonstrating.

## Initial provisioning 

The shell container has the initial provisioning scripts. The setup PKI, establishes the initial Root PKI, The Auth AppRole, and some initial AppRoles : 

    docker compose exec shell /bin/bash -c setup_pki.sh

Thw add_new_issuing, it creates a new Issuing certificate, signed by the root. It also setups a new policy, and adds the policy to the existing AppRoles.

    docker compose exec shell /bin/bash -c add_issuing.sh

This script will also add a reference to the current active certificate.

## Launching the server

The server is a basic python application that listens for a TLS connection, establishes the mTLS connection and prints out the received client certififcate information ( CommonName ). To get the required information, you run the 'get_cert.sh' script, followed by the server.py script. The get_certs.sh will generate role_id and secrets_id, then login with the server approle and get a certificate. It also downloads the Certificate chain to build the trust store.

    docker compose exec server /bin/bash -c get_cert.sh
    docker compose exec server /bin/bash -c server.py

## Launching the client

The client is a basic python application that connects to a server, establishes the mTLS connection and prints out the received server certififcate information ( CommonName ). To get the required information, you run the 'get_cert.sh' script, followed by the server.py script. The get_certs.sh will generate role_id and secrets_id, then login with the server approle and get a certificate. It also downloads the Certificate chain to build the trust store.

    docker compose exec client /bin/bash -c get_cert.sh
    docker compose exec client /bin/bash -c client.py

# Operational view

Now that everything is established, the client will continue sending information to the server every 30 seconds. The following are typical operational activities.

## Certificate rotation

As time moves on, the Issuing certificates wil eventually expire. Before that happens, they must be renewed. TO simplify the management and automation of the PKI infrastructure, if we keep to a few simple rules, everything will be simpler :

- Start using a new Issung certificates at 1/3 of the lifetime of the previous.
- Never create leaf certitificates > 2/3 of the lifetime of Issuing.

## New certificate end points

At the 1/3 mark, run `add_new_issuing.sh` this creates a new PKI endpoint, adds a new policy, appends the policy to all existing AppRoles and modifies the reference to the current_pki.

At this point, when a client renews, it will login with the existing role, and have the new policy. When it performs a lokup for the PKI reference, it will get a certificate from the NEW issuing certificate. It should also be getting the new CHAIN which includes the new certificate.

## New Application client (AppRole)

When adding a new application, this will need the polciies for the existing PKI roles, as well as the creation of a new PKI role. That is exactly wha tthe add_new_app scripts does.

## TODO

We are still missing :

- deletion of an expired PKI ( Issuing is expired )
- Rotation of the root ( Through it should be quite similar to the Issuing. )
- Runing of clean up operations ( tidy and clr )

# Further directions

while the application does demonstrate everything required, there are other directions that we can go.

## Client Authorisation

While the connection is considered secured, any cllient with a certificate signed by something in the trust store will be able to connect. The Common Name, considered secured, can now be used to discriminate between different clients (this is what etcd uses). Different hieriarchy points can also be used - either discriminate via the root server, or have a seperate intermediate certificate ( and chain). 

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

## Walking through it all 

vault list auth/approle/role

vault secrets list

vault list pki_int_20220302/roles

 vault read auth/approle/role/client
token_policies             [pki_role_20220302 default read_current_cert]
