# makessl

A Makefile which generates SSL keys and CSRs (and also certificates if you want).

It can also be used to manage an OpenVPN client network.

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

### Certificate verification

`make verify` will verify all generated and non-generated
certificates.  Any missing certificates will be generated.

## Managing OpenVPN

Set the make variable "VPNHOST" in [ssl-data.txt](ssl-data.txt) and
then run `make openvpn`.

This will generate an OpenVPN configuration file for each defined host
and create a .zip file which contains the configuration file and all
necessary supporting certificates into a single `.zip` file.  The file
is suitable for distribution.  The OpenVPN configuration file is based
on an editable template (see
[openvpn-config-template.conf](openvpn-config-template.conf)).

NOTE: On Windows, MAC, (most platforms) the extention `.ovpn` is
correct for OpenVPN to automatically recognize the configuration file.
However, on Linux servers this extention needs to be `.conf`.  The
generated `.zip` file contains copies of the configuration file with
both extentions.

CAVEATS:

OpenVPN does not seem to like certificate chains.  By default, this
Makefile does *NOT* use multi-level certificate chains -- every
certificate is signed with the root CA.  HOWEVER, if you set
`USE_INTERMEDIATE_CRT=yes` then the Makefile will generate and use an
intermediate signing certificate.  The current OpenVPN configuration
will not work in this mode.  Contributions/fixes for this welcome.

## License

This code is licensed under the GPL v2.  See LICENSE.txt for more details.