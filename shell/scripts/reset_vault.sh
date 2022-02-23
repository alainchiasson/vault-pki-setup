#!/usr/bin/env bash
#

# Using a preset Vault Root Token 
vault login root

vault secrets disable /pki_root
vault secrets disable /pki_int_0
vault secrets disable /pki_int_1
vault secrets disable /pki_int_2
#
vault auth disable approle