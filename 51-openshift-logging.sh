#!/bin/bash

source lib/utils.sh
source lib/status.sh

function install-openshift-logging-pre {
  # Create a project for OpenShift Logging
  execlog "oc create namespace $NAMESPACE_OPENSHIFT_LOGGING"
}

function install-openshift-logging-operators {
  # Install Operators
  execlog 'envsubst < integration/openshift-logging/openshift-logging-operators.yaml | oc apply -f -'
}

function install-openshift-logging-crs {
  # Install CRs, which may take 10mins
  execlog 'envsubst < integration/openshift-logging/openshift-logging-cr.yaml | oc apply -f -'
}

function install-openshift-logging-post {
  # Expose elasticsearch svc as route
  execlog "oc -n $NAMESPACE_OPENSHIFT_LOGGING expose svc elasticsearch"
  oc get service elasticsearch -o jsonpath={.spec.clusterIP} -n openshift-logging

  # Exposing the log store service as a route
  log "Exposing the log store service as a route" 
  # Ref: https://docs.openshift.com/container-platform/4.6/logging/config/cluster-logging-log-store.html#cluster-logging-elasticsearch-exposing_cluster-logging-store
  oc -n $NAMESPACE_OPENSHIFT_LOGGING extract secret/elasticsearch --to=. --keys=admin-ca
  cat > _elasticsearch_route.yaml <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: elasticsearch
  namespace: openshift-logging
spec:
  host:
  to:
    kind: Service
    name: elasticsearch
  tls:
    termination: reencrypt
    destinationCACertificate: | 
EOF
  cat ./admin-ca | sed -e "s/^/      /" >> _elasticsearch_route.yaml
  execlog "oc -n $NAMESPACE_OPENSHIFT_LOGGING apply -f _elasticsearch_route.yaml"

  # clean up
  rm -rf admin-ca
  rm -rf _elasticsearch_route.yaml
}

function how-to-access-openshift-logging-kibana {
  local url="$( oc get route -n $NAMESPACE_OPENSHIFT_LOGGING kibana -o json | jq -r .spec.host )"

  log "========================================================"
  log "Here is the info for how to access OpenShift Logging's Kibana UI:"
  log "- URL: $url"
  log "OpenShift authentication might be used so please proceed."
  log "========================================================"
}

function how-to-integrate-with-aiops {
  # ELK service URL
  local url="$( oc get route -n $NAMESPACE_OPENSHIFT_LOGGING elasticsearch -o json | jq -r .spec.host )"

  # extract token and test
  local es_token=$( oc -n $NAMESPACE_OPENSHIFT_LOGGING sa get-token cluster-logging-operator )
  local es_route=$( oc -n $NAMESPACE_OPENSHIFT_LOGGING get route elasticsearch -o jsonpath={.spec.host} )
  curl -tlsv1.2 --insecure -H "Authorization: Bearer ${es_token}" "https://${es_route}"

  # Kibana port
  local kibana_port="$( oc get svc -n $NAMESPACE_OPENSHIFT_LOGGING kibana -o json | jq -r '.spec.ports[0].port' )"

  log "========================================================"
  log "This is the key info for configuring ELK integration:"
  # Note: the suffix is actually the target index
  # in OpenShift Logging, there are two major index patterns: app-* and infra-*.
  # Please create that index in Kibana prior to creating the ELK integration with AIOps
  log "- ELK service URL: https://$url/app-*"
  log "- Token: $es_token"
  log "- Kibana port: $kibana_port"
  log "========================================================"

}
