# pki-endpoints

This is a list of all the pki endpoints currently in vault.

get     /pki/ca
get     /pki/ca/pem
get     /pki/ca_chain
get     /pki/cert/:serial
list    /pki/certs
post    /pki/config/ca
get     /pki/config/crl
post    /pki/config/crl
get     /pki/config/urls
post    /pki/config/urls
get     /pki/crl
get     /pki/crl/pem
get     /pki/crl/rotate
post    /pki/intermediate/generate/:type
post    /pki/intermediate/set-signed
post    /pki/issue/:name
post    /pki/revoke
post    /pki/roles/:name
get     /pki/roles/:name
list    /pki/roles
delete  /pki/roles/:name
post    /pki/root/generate/:type
delete  /pki/root
post    /pki/root/sign-intermediate
post    /pki/root/sign-self-issued
post    /pki/sign/:name
post    /pki/sign-verbatim(/:name)
post    /pki/tidy
get     /pki/tidy-status
