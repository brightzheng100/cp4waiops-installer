#!/bin/bash

source lib/utils.sh
source lib/status.sh

#
# This is to create a simple OpenLDAP service
#
function install-ldap {
    # Create a dedicated namespace
    execlog oc new-project $NAMESPACE_LDAP || true

    # Assign scc to ldap/default sa
    execlog oc adm policy add-scc-to-user anyuid system:serviceaccount:$NAMESPACE_LDAP:default

    # Install OpenLDAP
    execlog oc -n $NAMESPACE_LDAP create secret generic openldap --from-literal=adminpassword=$LDAP_ADMIN_PASSWORD
    # deploy
    execlog oc -n $NAMESPACE_LDAP apply -f integration/ldap/openldap.yaml
}

#
# post actions to populate data
#
function install-ldap-post {
    # Initialize the LDAP data
    local POD=$(oc -n $NAMESPACE_LDAP get pod -l app.kubernetes.io/name=openldap -o jsonpath="{.items[0].metadata.name}")
    # Copy over the ldif files
    execlog oc cp integration/ldap/ldif $NAMESPACE_LDAP/$POD:/
    execlog oc -n $NAMESPACE_LDAP exec $POD -- ls /ldif
    # Run the ldif files
    execlog oc -n $NAMESPACE_LDAP exec $POD -- ldapadd -x -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -H ldap:// -f /ldif/0-ous.ldif
    execlog oc -n $NAMESPACE_LDAP exec $POD -- ldapadd -x -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -H ldap:// -f /ldif/1-users.ldif
    execlog oc -n $NAMESPACE_LDAP exec $POD -- ldapadd -x -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -H ldap:// -f /ldif/2-groups.ldif

    # If LDAP is required: HUMIO_WITH_LDAP_INTEGRATED is true
    if [[ "${HUMIO_WITH_LDAP_INTEGRATED}" == "true" ]]; then
    execlog oc -n $NAMESPACE_LDAP exec $POD -- ldapadd -x -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -H ldap:// -f /ldif/2-groups-extra-for-humio.ldif
    fi

    # Verify the entities
    execlog oc -n $NAMESPACE_LDAP exec $POD -- ldapsearch -LLL -x -H ldap:// -D "cn=admin,dc=bright,dc=com" -w $LDAP_ADMIN_PASSWORD -b "ou=people,dc=bright,dc=com" dn
}