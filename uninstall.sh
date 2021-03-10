#!/bin/bash

source lib/utils.sh
source lib/status.sh
source 00-setup.sh
source 99-uninstall.sh

# To protect CS, we have a flag to indicate that
all="${1}"

# Uninstall Humio
uninstall-humio

# Uninstall Event Manager
uninstall-event-manager

# Uninstall AIManager
uninstall-aimanager

# Uninstall Common Services
if [[ "$all" == "all" ]]; then
uninstall-common-services
fi

# Uninstall post stuff
uninstall-aimanager-post-actions
uninstall-humio-post-actions

# Wait 2 mins
progress-bar 2

# Delete projects
oc delete project $NAMESPACE_HUMIO
oc delete project $NAMESPACE_CP4AIOPS
if [[ "$all" == "all" ]]; then
    # LDAP
    uninstall-ldap

    # NOTE: Delete CS namespace which may impact other services
    oc delete project $NAMESPACE_CS
fi
