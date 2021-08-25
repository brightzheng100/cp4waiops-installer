#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-turbonomic-pre {
  # Create a project for Turbonomic
  execlog "oc new-project $NAMESPACE_TURBONOMIC"
}

function install-turbonomic-operators {
  # Install Operators
  execlog "envsubst < integration/turbonomic/turbonomic-operators.yaml | oc apply -f -"

  # Grant permission to sa
  execlog "oc -n $NAMESPACE_TURBONOMIC adm policy add-scc-to-group anyuid system:serviceaccounts:$NAMESPACE_TURBONOMIC"
}

function install-turbonomic-crs {
  # Create CRs
  execlog 'envsubst < integration/turbonomic/turbonomic-cr.yaml | oc apply -f -'
}

function install-turbonomic-post-actions {
  # Nothing here yet
}

function how-to-access-turbonomic {
  local route="$( oc get route -n $NAMESPACE_TURBONOMIC api -o json | jq -r .spec.host )"

  log "========================================================"
  log "Here is the info for how to acess Turbonomic:"
  log "- URL: http://$route"
  log "Note: you can create the administrator account at first login."
  log "========================================================"
}
