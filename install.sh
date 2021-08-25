#!/bin/bash

source 00-setup.sh
source 10-common-services.sh
source 11-ldap.sh
source 12-openshift-serverless.sh
source 20-aiops.sh
source 30-extensions.sh
source 40-infra-automation.sh
source 50-humio.sh

# Confirmation
log "~~~~~~~~~~~~~~~~~~~~~     STARTING POINT    ~~~~~~~~~~~~~~~~~~~~~~~~~"
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
log "Installation is starting with the following configuration:"
log " ROKS                               = $ROKS"
log "---------"
log " The Namespace for Common Services  = $NAMESPACE_CS"
log " The Namespace for AI Ops Services  = $NAMESPACE_CP4WAIOPS"
log " The Namespace for Humio Services   = $NAMESPACE_HUMIO"
log " The StorageClass for File          = $STORAGECLASS_FILE"
log " The StorageClass for Block         = $STORAGECLASS_BLOCK"
log "---------"
log " HUMIO_WITH_LDAP_INTEGRATED         = $HUMIO_WITH_LDAP_INTEGRATED"
log "---------"
log " The to-be-skipped steps            = $SKIP_STEPS"
log " The logs file                      = $LOGFILE"
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
logn "Are you sure to proceed installation with these settings [Y/N]: "
read answer
if [ "$answer" != "Y" -a "$answer" != "y" ]; then
    log "Abort!"
    exit 99
fi

log "Great! Let's proceed the installation... "

missed_tools=0
log "Firstly, let's do a quick check for required tools..."
# check oc
if is_required_tool_missed "oc"; then missed_tools=$((missed_tools+1)); fi
# check jq
if is_required_tool_missed "jq"; then missed_tools=$((missed_tools+1)); fi
# check helm
if is_required_tool_missed "helm"; then missed_tools=$((missed_tools+1)); fi
# final check
if [[ $missed_tools > 0 ]]; then
  log "Abort! There are some required tools missing, please have a check."
  exit 98
fi

#
# 00. Prerequisites
# - If running in ROKS, let's explicitly set the default storageclass to ibmc-file-gold-gid
#
log "----------- 00. Prerequisites, if any --------------"
if [[ "${ROKS}" != "false" ]]; then 
log "----------- 01. StorageClasses in ROKS on Classic Infra --------------"
  # Change the default storageclass to ibmc-file-gold-gid
  execlog "oc patch storageclass/ibmc-block-gold -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"false\"}}}'"
  execlog "oc patch storageclass/ibmc-file-gold-gid -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"
fi

#
# To facilitate the install UX, there is a way to skip some steps for a better retry
# available SKIP_STEPS:
# - CS: Common Services
# - LDAP: OpenLDAP
# - SERVERLESS: OpenShift Serverless
# - AIOPS: AIOps with aiopsFoundation aiManager applicationManager components
# - EXTENSIONS: AIOps Extensions, if any
# - INFRA: Infrastructure Automation
# - HUMIO: Humio
#
# For example, to re-install only the AIOPS: 
# - export SKIP_STEPS="CS LDAP SERVERLESS EXTENSIONS INFRA HUMIO"
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
    # Pre
    install-common-services-pre
    # Install operators
    install-common-services-operators
    # Wait for 2 mins
    progress-bar 2
    # Install CRs
    install-common-services-crs
    # Wait for 5 mins
    #progress-bar 5
    # Check process, with timeout of 5mins, for expected 2 pods
    #check-namespaced-pod-status $NAMESPACE_CS 5 2
fi


###
#
# 11. LDAP, only when required
# 
# As of now, LDAP can be the dependency of:
# - Humio 
# 
############################################################
log "----------- 11. LDAP, only when required --------------"
if [[ "$HUMIO_ENABLED" == "true" ]] && [[ "$HUMIO_WITH_LDAP_INTEGRATED" == "true" ]]; then
    if [[ " ${SKIP_STEPS[@]} " =~ " LDAP " ]]; then
        log "----------- SKIPPED --------------"
    else
        # Pre
        install-ldap-pre
        # Install
        install-ldap
        # Wait for 1 mins
        progress-bar 1
        # Check process, with timeout of 5mins, for expected 1 pods
        check-namespaced-pod-status $NAMESPACE_LDAP 5 1
        # Post actions to populate data
        install-ldap-post
    fi
fi


###
#
# 12. OpenShift Serverless, which is explicitly required from v3.1.x
# 
############################################################
log "----------- 12. Prerequisites: OpenShift Serverless --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " SERVERLESS " ]]; then
    log "----------- SKIPPED --------------"
else
    # Pre
    install-openshift-serverless-pre
    # Install operators
    install-openshift-serverless-operators
    # Wait for 3 mins
    progress-bar 3
    # Install CRs
    install-openshift-serverless-crs
    # Wait for 5 mins
    progress-bar 5
    # Post actions
    install-openshift-serverless-post
fi


###
#
# 20. AIOps
# 
############################################################
log "----------- 20. AIOps --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " AIOPS " ]]; then
    log "----------- SKIPPED --------------"
else
    # Install AIOPs pre
    install-aiops-pre

    # Install AIOPs operators
    install-aiops-operators

    # Wait for 10 mins
    progress-bar 10

    # Install AIOPs CRs
    install-aiops-cr

    # Wait for 5 mins
    progress-bar 5

    # Check process with logs displayed, with timeout of 30mins, for expected 150 more pods in namespace
    # Something like this:
    # ------
    # NAME                  NAMESPACE       PHASE
    # default               <none>          <none>
    # evtmanager            ibm-cp4waiops   OK
    # aimanager             ibm-cp4waiops   Completed
    # evtmanager-topology   ibm-cp4waiops   OK
    # evtmanager            ibm-cp4waiops   OK
    # ------
    check-namespaced-pod-status-and-keep-displaying-logs-lines \
        "$NAMESPACE_CP4WAIOPS" \
        60 \
        165 \
        5 \
        "oc get Installation,noi,aimanager,asmformation,cemformation -A -o custom-columns='NAME:metadata.name,NAMESPACE:metadata.namespace,PHASE:status.phase'"

    # perform post actions
    install-aiops-post-actions
fi


###
#
# 30. AIOps Extensions
# 
############################################################
log "----------- 30. AIOps Extensions --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " EXTENSIONS " ]]; then
    log "----------- SKIPPED --------------"
else
    log "Nothing yet for AIOps extensions"
fi


###
#
# 40. Infrastructure Automation
# 
############################################################
log "----------- 40. Infrastructure Automation --------------"
if [[ " ${SKIP_STEPS[@]} " =~ " INFRA " ]]; then
    log "----------- SKIPPED --------------"
else
    log "Nothing yet for Infrastructure Automation"
fi


###
#
# 5x. Logging Stacks
# - 50 - Humio
# - 51 - OpenShift Logging, which is EFK stack
# 
############################################################
humio_decision=false
log "----------- 50. Humio --------------"
if [[ "$HUMIO_ENABLED" == "false" ]]; then
    log "----------- Humio is disabled, to enable it: export HUMIO_ENABLED=true --------------"
else
    if [[ " ${SKIP_STEPS[@]} " =~ " HUMIO " ]]; then
        log "----------- SKIPPED --------------"
    else
        # License
        license_content=""
        if [ -f "./_humio_license.txt" ]; then
            license_content="$( cat ./_humio_license.txt)"
            humio_decision=true
        else
            logn "there is no ./_humio_license.txt exists, you may try paste the license content here, then press enter: "
            read license_content_answer
            if [ "$license_content_answer" == "" ]; then
                log "Skip Humio since no license provided!"
            else
                echo $license_content_answer > ./_humio_license.txt
                humio_decision=true
            fi
        fi
        if [[ $humio_decision == true ]]; then
            # Pre
            install-humio-pre
            # Install operators
            install-humio-operators
            # Wait for 2 mins
            progress-bar 2
            # Install Humio Cluster
            install-humio-cluster
            # Check pod process, with timeout of 15mins, and >=7pods expected
            check-namespaced-pod-status $NAMESPACE_HUMIO 15 7
            # Install CRs
            install-humio-crs
            # Post actions
            install-humio-post-actions
            # Expose Humio svc "humio-cluster" for both http and es port
            oc expose svc humio-cluster -n $NAMESPACE_HUMIO --port="http"
            oc expose svc humio-cluster -n $NAMESPACE_HUMIO --name=humio-cluster-es --port="es"
        fi
    fi
fi

log "----------- 51. OpenShift Logging --------------"
openshift_logging_decision=false
if [[ "$OPENSHIFT_LOGGING_ENABLED" == "false" ]]; then
    log "----------- OpenShift Logging is disabled, to enable it: export OPENSHIFT_LOGGING_ENABLED=true --------------"
else
    if [[ " ${SKIP_STEPS[@]} " =~ " OPENSHIFT_LOGGING " ]]; then
        log "----------- SKIPPED --------------"
    else
        openshift_logging_decision=true
        # Pre
        install-openshift-logging-pre
        # Install operators
        install-openshift-logging-operators
        # Check pod process, with timeout of 5mins, and >=1pods expected
        check-namespaced-pod-status $NAMESPACE_OPENSHIFT_LOGGING 5 1
        # Install CRs
        install-openshift-logging-crs
        # Check pod process, with timeout of 10mins, and >=10pods expected
        check-namespaced-pod-status $NAMESPACE_OPENSHIFT_LOGGING 10 10
        # Post actions
        install-openshift-logging-post
    fi
fi

log "----------- 60. Turbonomic --------------"
turbonomic_decision=false
if [[ "$TURBONOMIC_ENABLED" == "false" ]]; then
    log "----------- Turbonomic is disabled, to enable it: export TURBONOMIC_ENABLED=true --------------"
else
    if [[ " ${SKIP_STEPS[@]} " =~ " TURBONOMIC " ]]; then
        log "----------- SKIPPED --------------"
    else
        turbonomic_decision=true
        # Pre
        install-turbonomic-pre
        # Install operators
        install-turbonomic-operators
        # Check pod process, with timeout of 5mins, and >=1pods expected
        check-namespaced-pod-status $NAMESPACE_TURBONOMIC 5 1
        # Install CRs
        install-turbonomic-crs
        # Check pod process, with timeout of 10mins, and >=10pods expected
        check-namespaced-pod-status $NAMESPACE_TURBONOMIC 10 10
        # Post actions
        install-turbonomic-post
    fi
fi

###
#
# Conclusion, if we can reach here
# 
############################################################
log "~~~~~~~~~~~~~~~~~~~~~~~~~~~ Conclusion ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

# Display how to access IBM Cloud Pak for Watson AIOps console
how-to-access-aiops-console

# Display how to access Humio, if it's installed
if [[ "$HUMIO_ENABLED" == "true" ]] || [[ $humio_decision == true ]]; then
how-to-access-humio
fi

# Display how to access Turbonoic, if it's installed
if [[ "$TURBONOMIC_ENABLED" == "true" ]] || [[ $turbonomic_decision == true ]]; then
how-to-access-turbonomic
fi

# Display how to access Kibana and expose necessary info for AIOps integration, if it's installed
if [[ "$OPENSHIFT_LOGGING_ENABLED" == "true" ]] || [[ $openshift_logging_decision == true ]]; then
how-to-access-openshift-logging-kibana
how-to-integrate-with-aiops
fi

log "~~~~~~~~~~~~~~~~~~~~~~~~~~~ What's Next? ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
log "Please check out the doc for the next: https://www.ibm.com/docs/en/cloud-paks/cp-waiops/3.1.1?topic=installing-postinstallation-tasks"


log "~~~~~~~~~~~~~~~~~~~~~~~~~~~  THE END!  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
