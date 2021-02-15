#!/bin/bash

source lib/utils.sh
source lib/status.sh
source 00-setup.sh
source 99-uninstall.sh

# Uninstall Humio
uninstall-humio

# Uninstall Event Manager
uninstall-event-manager

# Uninstall AIManager
uninstall-aimanager

# Uninstall Common Services
uninstall-common-services

# Uninstall post stuff
uninstall-aimanager-post-actions
uninstall-humio-post-actions

# Wait 2mins
progress-bar 120

# Delete projects
oc delete project $NAMESPACE_HUMIO
oc delete project $NAMESPACE_CP4AIOPS
oc delete project $NAMESPACE_CS
