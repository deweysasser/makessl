# makessl

A Makefile which generates SSL keys and CSRs (and also certificates if you want)

## Giving the certificates your own data

The data used for the certificate information can be found in
ssl-data.txt.  You should edit this file to contain information valid
for your certificates.

## Using

To generate a CSR for a new host

     mkdir -p hosts/www.example.com
     make

To generate a new certificate (or set of certificates);

     mkdir -p hosts/www.example.com
     make certs

To generate certificate bundles for all hosts (this will implicitly make all certificates as well):

     make bundles

## Certificate Authority

If you use 'make certs', a root certificate authority and signing key
will be generated for you. You'll need the file ca/ca-chain.pem as a
certificate chain.

## License

This code is licensed under the GPL v2.  See LICENSE.txt for more details.