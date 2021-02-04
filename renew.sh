#!/bin/sh
set -e

# =========================================================================== #
#             Date:           Do 3. Dez 08:26:04 CET 2020                     #
#      Description:    Script for renewal the SSO source in VMWare vCenter    #
#       Maintainer:       Tim Rabl ( https://github.com/timrabl/ )            #
# =========================================================================== #

get_new_cert() {
    SERVER=$1; shift
    PORT=$1; shift
    OUT=$1; shift

    echo "" | \
        openssl s_client -servername $SERVER -connect $SERVER:$PORT 2>/dev/null | \
        openssl x509 -out $OUT
}

delete_identity_source() {
    NAME=$1; shift

    IDENTITY_SOURCE=$(sso-config.sh -get_identity_sources | \
        grep IdentitySourceName | grep $NAME | awk -F ':' '{ print $2 }' | \
        sed -E 's/[[:blank:]]+//g')

    [ ! -z $IDENTITY_SOURCE ] && sso-config.sh -delete_identity_source -i $IDENTITY_SOURCE
}

set_identity_source() {

    LDAP_BASE_USER_DN=$1; shift
    LDAP_BASE_GROUP_DN=$1; shift
    DOMAIN=$1; shift
    ALIAS=$1; shift
    USERNAME=$1; shift
    PASSWORD=$1; shift
    LDAP_SERVER_URL=$1; shift
    LDAP_SERVER_PORT=$1; shift
    LDAP_SSL_ENABLE=$1; shift
    LDAP_SSL_CERT=$1; shift


    sso-config.sh \
	    -add_identity_source \
	    -type openldap \
	    -baseUserDN $LDAP_BASE_USER_DN \
	    -baseGroupDN $LDAP_BASE_GROUP_DN \
        -domain $DOMAIN \
        -alias $ALIAS \
        -username $USERNAME \
        -password $PASSWORDS \
        -primaryURL "$LDAP_SERVER_URL:$LDAP_SERVER_PORT" \
        -useSSL true \
        -sslCert $LDAP_SSL_CERT
}

# =========================== REPLACE THESE VARS ============================ #

SERVER="<< REPLACE WITH LDAP SERVER URL >>"
PORT="<< REPLACE WITH LDAP SERVER PORT >>"

LDAP_USER_DN="<< REPLACE WITH LDAP USER DN >>"
LDAP_GROUP_DN="<< REPLACE WITH LDAP GROUP DN >>"
SSO_DOMAIN="<< REPLACE WITH SSO DOMAIN >>"
SSO_ALIAS="<< REPLACE WITH SSO ALIAS >>"
LDAP_USERNAME="<< REPLACE WITH LDAP USER >>"
LDAP_PASSWORD="<< REPLACE WITH LDAP PASSWORD >>"

# =========================================================================== #

SSO_NAME="SSO_$SERVER"
PEMFILE="$SERVER.pem"

# Obtain new PEM file
get_new_cert $SERVER $PORT $PEMFILE

# Delete existing Identity Source in VMWare
delete_identity_source $SSO_NAME

# Set SingleSingOn source for VMWare vCenter
set_identity_source $LDAP_USER_DN $LDAP_GROUP_DN $SSO_DOMAIN $SSO_ALIAS \
    $LDAP_USERNAME $LDAP_PASSWORD $SERVER $PORT $PEMFILE

rm $PEMFILE
