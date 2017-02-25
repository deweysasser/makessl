######################################################################
# Purpose: Generate SSL keys, certificates and requests easily and
# managably
######################################################################

# Properties of the Certificates (who you are)
include ssl-data.txt


# Properties of the keys (you probably don't want to change this)
CAEXPIRATION=3650
EXPIRATION=365
KEYSIZE=4096


# The rest of this is implementation -- you probably don't want to edit it
ROOTCRT=ca/$(addsuffix -root.crt, $(ORG))
ROOTKEY=ca/$(addsuffix -root.key, $(ORG))

SIGNINGKEY=ca/$(addsuffix -signing.key, $(ORG))
SIGNINGCA=ca/$(addsuffix -signing.crt, $(ORG))
SIGNINGCSR=ca/$(addsuffix -signing.csr, $(ORG))

DIRS=$(wildcard hosts/*)
BASES=$(foreach name,$(DIRS), $(name)/$(shell echo $(notdir $(name)) | tr -- -. __))
CSRS=$(addsuffix .csr, $(BASES))
CRTS=$(addsuffix .crt, $(BASES))
KEYS=$(addsuffix .key, $(BASES))
BUNDLES=$(addsuffix .bundle, $(BASES))

.PRECIOUS: %.key

justdir= $(lastword $(subst /, , $(dir $1)))

csrs: $(CSRS)

certs: $(SIGNINGCA) $(CRTS) 

bundles: $(BUNDLES)

all: $(CSRS)

# To make a key...
%.key:
	mkdir -p `dirname $@`
	openssl genrsa $(KEYSIZE) > $@


# To make a CSR from a key
%.csr: %.key
	openssl req -nodes -subj "/C=$(COUNTRY)/OU=$(OU)/ST=$(ST)/L=$(LOCALITY)/O=$(ORG)/CN=$(call justdir, $@)" -out $@ -key $< -new


# To make a CRT from a CSR
%.crt: %.csr $(ROOTCRT)
	openssl x509 -req -in $< -CA $(SIGNINGCA) -CAkey $(SIGNINGKEY) -CAcreateserial -days $(EXPIRATION) -out $@
	openssl verify -CAfile ca/ca-chain.pem $@

# To make a certificate bundle
%.bundle: %.crt $(ROOTCRT)
	cat ca/ca-chain.pem $< > $@

# Signing key magic.  First the root key
$(ROOTCRT): $(ROOTKEY)
	openssl req -new -x509 -days $(CAEXPIRATION) -subj "/C=$(COUNTRY)/OU=$(OU)/ST=$(ST)/L=$(LOCALITY)/O=$(ORG)/CN=$(ORG) Certificate Authority" -key $< -out $@ 

# Now the signing key, which is signed by the root key
$(SIGNINGCA): $(SIGNINGKEY) $(ROOTCRT)
	openssl req -nodes -subj "/C=$(COUNTRY)/OU=$(OU)/ST=$(ST)/L=$(LOCALITY)/O=$(ORG)/CN=$(ORG) signing key" -out $(SIGNINGCSR) -key $(SIGNINGKEY) -new
	openssl x509 -req -in $(SIGNINGCSR) -CA $(ROOTCRT) -CAkey $(ROOTKEY) -CAcreateserial -days $(EXPIRATION) -out $(SIGNINGCA)
	openssl verify -CAfile $(ROOTCRT) $(SIGNINGCA)
	cat $(ROOTCRT) $(SIGNINGCA) > ca/ca-chain.pem


hosts:
	mkdir $@