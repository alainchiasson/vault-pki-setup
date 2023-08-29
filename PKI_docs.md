# PKI Docs 

The following ar ethe new commands added in Vault 1.13 (https://developer.hashicorp.com/vault/docs/v1.13.x/commands/pki)


- vault pki health-check mount
- vault pki verify-sign parent child
- vault pki list-intermediates parent
- vault pki issue parent-mount issuer-mount
- vault pki reissue parent-mount issuer-mount

These are helper commands, but are acompanied by API endpoints.

## The new way to create a CA path

 Using a preset Vault Root Token 
vault login root

# Enable the pki
vault secrets enable -path=pki_root pki

# generate root certificates ( and export )
vault write -format=json /pki_root/root/generate/exported common_name="Dev Root" | tee root.json

jq -r '.data.certificate'   root.json | tee root.cert.pem
jq -r '.data.issuing_ca'    root.json | tee root.ca.pem
jq -r '.data.private_key'   root.json | tee root.key.pem
jq -r '.data.serial_number' root.json | tee root.serial.pem

# Test the new commands 

vault pki health-check pki_root   # Offers tons of sec info.

vault pki list-intermediates pki_root

# Add another mount 

vault secrets enable -path=pki_int_one pki

# Initialise the the certificates fo rthe issuing.
vault write -format=json /pki_int_one/intermediate/generate/exported common_name="DEV Issuing one" | tee iss-pki_int_one-gen.json

jq -r '.data.csr'               iss-pki_int_one-gen.json | tee iss-pki_int_one.csr.pem
jq -r '.data.private_key'       iss-pki_int_one-gen.json | tee iss-pki_int_one.key.pem

vault pki issue -format=json  -issuer_name="First" /pki_root/issuer/default /pki_int_one/ common_name="first-department.example.com" | tee iss-pki_int_one-gen.cert.json

jq -r '.data.certificate'   iss-pki_int_one-gen.cert.json | tee iss-pki_int_one-gen.cert.pem
jq -r '.data.issuing_ca'    iss-pki_int_one-gen.cert.json | tee iss-pki_int_one-gen.ca.pem
jq -r '.data.private_key'   iss-pki_int_one-gen.cert.json | tee iss-pki_int_one-gen.key.pem
jq -r '.data.serial_number' iss-pki_int_one-gen.cert.json | tee iss-pki_int_one-gen.serial.pem

jq -r '.data.ca_chain'      iss-pki_int_one-gen.cert.json | tee iss-pki_int_one-gen.chain.pem
jq -r '.data.ca_chain[0]'   iss-pki_int_one-gen.cert.json | tee iss-pki_int_one-gen.chain-0.pem
jq -r '.data.ca_chain[1]'   iss-pki_int_one-gen.cert.json | tee iss-pki_int_one-gen.chain-1.pem

