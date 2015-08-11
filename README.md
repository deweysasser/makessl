# makessl

A Makefile which generates SSL keys and CSRs (and also certificates if you want)

## Using

To generate a CSR for a new host

     mkdir -p hosts/www.example.com
     make

To generate a new certificate (or set of certificates);

     mkdir -p hosts/www.example.com
     make certs

## Certificate Authority

If you use 'make certs', a root certificate authority and signing key
will be generated for you. You'll need the file ca/ca-chain.pem as a
certificate chain.
