######################################################################
# Purpose: Generate SSL keys, certificates and requests easily and
# managably
######################################################################

# Properties of the Certificates (who you are)
include ssl-data.txt

USE_INTERMEDIATE_CRT?=no


# Properties of the keys (you probably don't want to change this)
CAEXPIRATION=3650
EXPIRATION=365
KEYSIZE=4096


# The rest of this is implementation -- you probably don't want to edit it
ROOTCRT=ca/$(addsuffix -root.crt, $(ORG))
ROOTKEY=ca/$(addsuffix -root.key, $(ORG))

ifeq ($(USE_INTERMEDIATE_CRT),yes)
SIGNINGKEY=ca/$(addsuffix -signing.key, $(ORG))
SIGNINGCRT=ca/$(addsuffix -signing.crt, $(ORG))
SIGNINGCSR=ca/$(addsuffix -signing.csr, $(ORG))
else
SIGNINGKEY=$(ROOTKEY)
SIGNINGCRT=$(ROOTCRT)
endif

CACHAIN=ca/ca-chain.pem

DIRS=$(wildcard hosts/*)
BASES=$(foreach name,$(DIRS), $(name)/$(shell echo $(notdir $(name)) | tr -- -. __))
CSRS=$(addsuffix .csr, $(BASES))
CRTS=$(addsuffix .crt, $(BASES))
KEYS=$(addsuffix .key, $(BASES))
BUNDLES=$(addsuffix .bundle, $(BASES))
OVPNFILES=$(addsuffix -$(VPNHOST)-openvpn.zip, $(filter-out hosts/$(VPNHOST)/%,$(BASES))) 

.PRECIOUS: %.key

justdir= $(lastword $(subst /, , $(dir $1)))

csrs: $(CSRS)

certs: $(SIGNINGCRT) $(CRTS) 

bundles: $(BUNDLES)

openvpn: openvpn-check $(OVPNFILES)

all: $(CSRS)

# To make a key...
%.key:
	mkdir -p `dirname $@`
	openssl genrsa $(KEYSIZE) > $@


# To make a CSR from a key
%.csr: %.key
	openssl req -nodes -subj "/C=$(COUNTRY)/OU=$(OU)/ST=$(ST)/L=$(LOCALITY)/O=$(ORG)/CN=$(call justdir, $@)" -out $@ -key $< -new


# To make a CRT from a CSR
%.crt: %.csr $(SIGNINGCRT) $(CACHAIN)
	openssl x509 -req -in $< -CA $(SIGNINGCRT) -CAkey $(SIGNINGKEY) -CAcreateserial -days $(EXPIRATION) -out $@
	openssl verify -CAfile $(CACHAIN) $@

ifeq ($(USE_INTERMEDIATE_CRT),yes)
verify: $(SIGNINGCRT).verify $(addsuffix .verify,$(BASES))
else
verify: $(addsuffix .verify,$(BASES))
endif

%.verify: %.crt %.bundle $(CACHAIN)
	@echo "Verify $*.crt"
	openssl verify -CAfile $(CACHAIN) $*.crt
	openssl verify -CAfile $(ROOTCRT) $*.bundle
	@echo "diffing key and crt modulous"
	@bash -c "diff <(openssl rsa -noout -modulus -in $*.key) <(openssl x509 -noout -modulus -in $*.crt)"

# To make a certificate bundle
%.bundle: %.crt $(CACHAIN)
	cat $(CACHAIN) $< > $@

export CLIENT SERVER ORG CLIENT_CERT_TEXT

TOOLS=$(CURDIR)/tools

%-$(VPNHOST)-openvpn.zip: SERVER=$(VPNHOST)
%-$(VPNHOST)-openvpn.zip: CLIENT=$(notdir $(subst -$(VPNHOST)-openvpn.zip,,$@))
%-$(VPNHOST)-openvpn.zip: openvpn-client-template.conf %.key %.bundle $(ROOTCRT) $(SIGNINGCRT) $(CACHAIN)
	echo CLIENT=$(CLIENT)
	echo SERVER=$(SERVER)
	perl $(TOOLS)/pp -I ca -I $(dir $@) $< | tee $(dir $@)/$(VPNHOST).ovpn > $(dir $@)/$(VPNHOST).conf
	zip -j $@ $(dir $@)/$(VPNHOST).{ovpn,conf} $(dir $@)/*.{key,crt,bundle} $(ROOTCRT) $(SIGNINGCRT) $(CACHAIN)

%-openvpn.zip: %.key %.crt %.ovpn


# Signing key magic.  First the root key
$(ROOTCRT): $(ROOTKEY)
	openssl req -new -x509 -days $(CAEXPIRATION) -subj "/C=$(COUNTRY)/OU=$(OU)/ST=$(ST)/L=$(LOCALITY)/O=$(ORG)/CN=$(ORG) Certificate Authority" -key $< -out $@ 

# Now the signing key, which is signed by the root key
ifeq ($(USE_INTERMEDIATE_CRT),yes)
$(SIGNINGCRT): $(SIGNINGKEY) $(ROOTCRT)
	openssl req -nodes -subj "/C=$(COUNTRY)/OU=$(OU)/ST=$(ST)/L=$(LOCALITY)/O=$(ORG)/CN=$(ORG) signing key" -out $(SIGNINGCSR) -key $(SIGNINGKEY) -new
	openssl x509 -req -in $(SIGNINGCSR) -CA $(ROOTCRT) -CAkey $(ROOTKEY) -CAcreateserial -days $(EXPIRATION) -out $(SIGNINGCRT)
	openssl verify -CAfile $(ROOTCRT) $(SIGNINGCRT)

endif

$(CACHAIN): $(SIGNINGCRT) $(ROOTCRT)
	cat $^ > $@


openvpn-check:
	@if [ -z "$(VPNHOST)" ] ; then echo VPNHOST variable is not set; exit 1; fi

hosts:
	mkdir $@

distclean:
	rm -rf ca hosts/*/*

info::
	@echo DIRS=$(DIRS)
	@echo BASES=$(BASES)
	@echo KEYS=$(KEYS)
	@echo CERTS=$(CRTS)
	@echo BUNDLES=$(BUNDLES)
	@echo OVPN Files=$(OVPNFILES)
	@echo VPN Host=$(VPNHOST)
	@echo Using intermediate cert?  $(USE_INTERMEDIATE_CRT) $(origin USE_INTERMEDIATE_CRT)
	@echo Signing crt: $(SIGNINGCRT)

