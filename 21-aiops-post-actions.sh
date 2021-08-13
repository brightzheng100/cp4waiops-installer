#!/bin/bash

source lib/utils.sh
source lib/status.sh

function update-aiops-cert {
  log "Updating AIOps TLS Cert so that we can integrate with Slack properly"

  # Update the AIOps cert
  oc -n $NAMESPACE_CP4WAIOPS delete AutomationUIConfig iaf-system
  envsubst < manifests/aiops-cert.yaml | oc apply -f -

  # collect certificate from OpenShift ingress
  ingress_pod=$(oc get secrets -n openshift-ingress | grep tls | grep -v router-metrics-certs-default | awk '{print $1}')
  oc get secret -n openshift-ingress -o 'go-template={{index .data "tls.crt"}}' ${ingress_pod} | base64 -d > cert.crt
  oc get secret -n openshift-ingress -o 'go-template={{index .data "tls.key"}}' ${ingress_pod} | base64 -d > cert.key
  # backup existing secret
  oc -n $NAMESPACE_CP4WAIOPS get secret external-tls-secret -o yaml > external-tls-secret.yaml
  # delete existing secret
  oc -n $NAMESPACE_CP4WAIOPS delete secret external-tls-secret
  # create new secret
  oc -n $NAMESPACE_CP4WAIOPS create secret generic external-tls-secret --from-file=cert.crt=cert.crt --from-file=cert.key=cert.key --dry-run=client -o yaml | oc apply -f -
  # scale down nginx
  oc -n $NAMESPACE_CP4WAIOPS scale Deployment/ibm-nginx --replicas=0
  # scale up nginx
  sleep 3
  oc -n $NAMESPACE_CP4WAIOPS scale Deployment/ibm-nginx --replicas=1

  # clean up
  rm -f cert.crt
  rm -f cert.key
  rm -f external-tls-secret.yaml
}

function install-event-manager-gateway {
  log "Installing Event Manager Gateway to enable event data to flow from the event management component to the AI Manager"

  execlog 'envsubst < manifests/aiops-event-manager-gateway.yaml | oc apply -f -'
}