#!/bin/bash

source lib/utils.sh
source lib/status.sh

#
# This is to create a simple OpenLDAP service
#
function install-ldap {
    # Create a dedicated namespace
    execlog oc new-project ldap || true

    # Assign scc to ldap/default sa
    execlog oc adm policy add-scc-to-user anyuid system:serviceaccount:ldap:default

    # Install OpenLDAP
    execlog oc -n ldap create secret generic openldap --from-literal=adminpassword=$LDAP_ADMIN_PASSWORD
    # deploy
    execlog oc -n ldap apply -f integration/ldap/openldap.yaml
}

#
# post actions to populate data
#
function install-ldap-post {
    # Initialize the LDAP data
    local POD=$(oc -n ldap get pod -l app.kubernetes.io/name=openldap -o jsonpath="{.items[0].metadata.name}")
    # Copy over the ldif files
    execlog oc cp integration/ldap/ldif ldap/$POD:/
    execlog oc -n ldap exec $POD -- ls /ldif
    # Run the ldif files
    execlog oc -n ldap exec $POD -- ldapadd -x -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -H ldap:// -f /ldif/0-ous.ldif
    execlog oc -n ldap exec $POD -- ldapadd -x -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -H ldap:// -f /ldif/1-users.ldif
    execlog oc -n ldap exec $POD -- ldapadd -x -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -H ldap:// -f /ldif/2-groups.ldif

    # Verify the entities
    execlog oc -n ldap exec $POD -- ldapsearch -LLL -x -H ldap:// -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -b "ou=people,dc=bright,dc=com" dn
}