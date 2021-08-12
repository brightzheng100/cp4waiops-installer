#!/bin/bash

source lib/utils.sh
source lib/status.sh
source 00-setup.sh
source 99-uninstall.sh

# To protect CS, we have a flag to indicate that
all="${1}"

# Uninstall Humio
uninstall-humio

# Uninstall AIOps
uninstall-aiops

# Uninstall post stuff
uninstall-humio-post-actions
uninstall-aiops-post-actions

# Wait 2 mins
progress-bar 2

# Delete projects
oc delete project $NAMESPACE_HUMIO
oc delete project $NAMESPACE_CP4WAIOPS
purge_namespace $NAMESPACE_CP4WAIOPS

# Further clean-up
if [[ "$all" == "all" ]]; then
    # Common Services
    uninstall-common-services

    # LDAP
    uninstall-ldap

    # NOTE: Delete CS namespace which may impact other services
    oc delete project $NAMESPACE_CS
fi
