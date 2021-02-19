#!/bin/bash

source 00-setup.sh
source 10-common-services.sh
source 20-aiops.sh
source 30-event-manager.sh
source 40-aimanager.sh
source 50-humio.sh

# Confirmation
log "~~~~~~~~~~~~~~~~~~~~~     STARTING POINT    ~~~~~~~~~~~~~~~~~~~~~~~~~"
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
log "Installation is starting with the following configuration:"
log " ROKS                               = $ROKS"
log " The Namespace for Common Services  = $NAMESPACE_CS"
log " The Namespace for AI Ops Services  = $NAMESPACE_CP4AIOPS"
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
logn "Are you sure to proceed installation with these settings [Y/N]: "
read answer
if [ "$answer" != "Y" -a "$answer" != "y" ]; then
    log "Abort!"
    exit 99
fi

log "Great! Let's proceed the installation... "

#
# To facilitate the install UX, there is a way to skip some steps for a better retry
# available SKIP_STEPS:
# - CS: Common Services
# - AIOPS: AI Ops
# - EVENTMANAGER: Event Manager
# - AIMANAGER: AI Manager
# - HUMIO: Humio
#
# For example, to re-install only the AIManager: 
# - export SKIP_STEPS="CS AIOPS EVENTMANAGER"
#
SKIP_STEPS=("${SKIP_STEPS}")

###
#
# 10. Common Services
# 
############################################################
log "----------- 10. Common Services --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " CS " ]]; then
    log "----------- SKIPPED --------------"
else
    # Install
    install-common-services
    # Wait for 2 mins
    progress-bar 2
    # Check process, with timeout of 2mins
    check-namespaced-pod-status $NAMESPACE_CS 2
fi


###
#
# 20. AI Ops
# 
############################################################
log "----------- 20. AI Ops --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " AIOPS " ]]; then
    log "----------- SKIPPED --------------"
else
    # Install
    install-aiops
    # Wait for 3 mins
    progress-bar 3
    # Check process, with timeout of 3mins
    check-namespaced-pod-status $NAMESPACE_CP4AIOPS 3
fi

###
#
# 30. Event Manager
# 
############################################################
log "----------- 30. Event Manager --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " EVENTMANAGER " ]]; then
    log "----------- SKIPPED --------------"
else
    # Install
    install-event-manager
    # Wait for 10 mins
    progress-bar 10
    # Check process, with timeout of 20mins
    check-namespaced-pod-status $NAMESPACE_CP4AIOPS 20
fi


###
#
# 40. AI Manager
# 
############################################################
log "----------- 40. AI Manager --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " AIMANAGER " ]]; then
    log "----------- SKIPPED --------------"
else
    # Install
    install-aimanager
    # Wait for 10 mins
    progress-bar 10
    # Check pod process, with timeout of 30mins
    check-namespaced-pod-status $NAMESPACE_CP4AIOPS 30
    # Check further for AIManager's post actions, with timeout of another 20mins
    check-namespaced-object-presence-and-keep-displaying-logs-lines \
      "$NAMESPACE_CP4AIOPS" \
      'route/ibm-cp4aiops-cpd' \
      "oc logs $( oc get pod -n $NAMESPACE_CP4AIOPS | grep ibm-cp-data-operator | awk {'print $1'} ) -n $NAMESPACE_CP4AIOPS | grep -E '(0010-infra x86_64|0015-setup x86_6|0020-core x86_64)' | tail -3" \
      20
fi


###
#
# 50. Humio
# 
############################################################
log "----------- 50. Humio --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " HUMIO " ]]; then
    log "----------- SKIPPED --------------"
else
    # Install
    install-humio
    # Wait for 2 mins
    progress-bar 2
    # Check pod process, with timeout of 15mins
    check-namespaced-pod-status $NAMESPACE_HUMIO 15
    # Expose Humio svc "humio-cluster" for both http and es port
    oc expose svc humio-cluster -n $NAMESPACE_HUMIO --port="http"
    oc expose svc humio-cluster -n $NAMESPACE_HUMIO --name=humio-cluster-es --port="es"
fi


###
#
# Conclusion, if we can reach here
# 
############################################################
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~ Conclusion ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# Display how to access Event Manager
how-to-access-event-manager
# Display how to access AIManager
how-to-access-aimanager
# Display how to access Humio
how-to-access-humio


log "~~~~~~~~~~~~~~~~~~~~~~~~~~~  THE END!  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
