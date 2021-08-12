#!/bin/bash

# 
# Sleep until all specified namespace's pods are running/completed.
#
# Sample usage:
# - To check $NAMESPACE_CP4WAIOPS and expect at least 3 pods, with 5mins timeout
#       check-namespaced-pod-status $NAMESPACE_CP4WAIOPS 5 3
#
function check-namespaced-pod-status {
    local namespace="$1"
    local timeout_min=$2
    local expected_pods_min="${3:-1}"           # optional, defaults to 1

    local wc_all=0
    local wc_remaining=0

    log "--------------------------"

    finished=false
    for ((time=1;time<$timeout_min;time++)); do
        wc_all="`oc get po --no-headers=true -n $namespace | grep 'Running\|Completed' | wc -l  | xargs`"
        wc_remaining="`oc get po --no-headers=true -n $namespace | grep -v 'Running\|Completed' | wc -l | xargs`"
        
        log "Waiting for pods in ns ($namespace) to be running/completed: expected >= $expected_pods_min; current = $wc_all; ongoing = $wc_remaining... recheck in $time of $timeout_min mins"
        
        if [ $wc_remaining -le 0 ] && [ $wc_all -ge $expected_pods_min ]; then
            # no more remaining
            finished=true
            log "DONE!"
            break
        else
            echo ""
            oc get po -n $namespace | grep -v 'Running\|Completed'
        fi

        # wait 1 min
        progress-bar 1
    done

    if [[ "$finished" == "false" ]]; then
        log "Hmm, timeout after retrying in $timeout_min mins!"
        exit 99
    fi
}

# 
# Keep checking whether all specified namespace's pods are running/completed,
# while displaying some log lines by a specific command
#
# == Paramaters ==
# $1 - namespace
# $2 - timeout in minute
# $3 - minimum num of expected pods
# $4 - igmorable num of pods
# $5 - the command to run for scaping the logs / info
#
# == Sample Usage ==
# - Check and wait "route/ibm-cp4aiops-cpd" presence and keep displaying last 3 lines of post actions status, with 10mins timeout
#   $ check-namespaced-pod-status-and-keep-displaying-logs-lines \
#           "$NAMESPACE_CP4WAIOPS" \
#           60 \
#           165 \
#           5 \
#           "oc get Installation,noi,aimanager,asmformation,cemformation -A -o custom-columns='NAME:metadata.name,NAMESPACE:metadata.namespace,PHASE:status.phase'" \
#
function check-namespaced-pod-status-and-keep-displaying-logs-lines {
    local namespace="$1"
    local timeout_min=$2
    local expected_pods_min="$3"
    local ignorable_pods="$4"
    local display_command="$5"

    local wc_all=0
    local wc_remaining=0

    log "--------------------------"

    finished=false
    for ((time=1;time<$timeout_min;time++)); do
        wc_all="`oc get po --no-headers=true -n $namespace | grep 'Running\|Completed' | wc -l  | xargs`"
        wc_remaining="`oc get po --no-headers=true -n $namespace | grep -v 'Running\|Completed' | wc -l | xargs`"

        # display logs
        execlog $display_command
        
        log "Waiting for pods in ns ($namespace) to be running/completed: expected >= $expected_pods_min; current = $wc_all; ongoing = $wc_remaining... recheck in $time of $timeout_min mins"
        
        if [ $wc_remaining -le $ignorable_pods ] && [ $wc_all -ge $expected_pods_min ]; then
            # no more remaining, or just a few ignorable pods
            finished=true
            log "DONE!"
            break
        else
            echo ""
            oc get po -n $namespace | grep -v 'Running\|Completed'
        fi

        # wait 1 min
        progress-bar 1
    done

    if [[ "$finished" == "false" ]]; then
        log "Hmm, timeout after retrying in $timeout_min mins!"
        exit 99
    fi
}

# 
# Sleep until a specific object is present (as the signal of completion).
# Sample usage:
# - check-namespaced-object-presence "$NAMESPACE_CP4WAIOPS" "route/ibm-cp4aiops-cpd" 10
#
function check-namespaced-object-presence {
    local namespace="$1"
    local kind_name="$2"
    local timeout_min=$3
    
    log "--------------------------"

    finished=false
    for ((time=1;time<$timeout_min;time++)); do
        exist_check="`oc get $kind_name --no-headers=true -n $namespace | wc -l | xargs`"
        log "Waiting for $kind_name in ns $namespace to be present... recheck in $time of $timeout_min mins"
        
        if [ $exist_check -eq 1 ]; then
            # yes, it's present
            finished=true
            log "Yep, it's present now!"
            break
        else
            echo ""
        fi

        # wait for 1 min
        progress-bar 1
    done

    if [[ "$finished" == "false" ]]; then
        log "Hmm, timeout after retrying in $timeout_min mins!"
        exit 99
    fi
}

# 
# Keep checking the presence of some specific objects, 
# while displaying some log lines by a specific command
#
# Sample usage:
# - Check and wait "route/ibm-cp4aiops-cpd" presence and keep displaying last 3 lines of post actions status, with 10mins timeout
#   $ check-namespaced-object-presence-and-keep-displaying-logs-lines \
#       "$NAMESPACE_CP4WAIOPS" \
#       "route/ibm-cp4aiops-cpd" \
#       "oc logs $( kgp -n ibm-cp4aiops | grep ibm-cp-data-operator | awk {'print $1'} ) -n $NAMESPACE_CP4WAIOPS | grep -E '0010-infra x86_64   \|                \||0015-setup x86_64   \|                \||0020-core x86_64    \|                \|' | tail -3" \
#       10
#
function check-namespaced-object-presence-and-keep-displaying-logs-lines {
    local namespace="$1"
    local kind_name="$2"
    local display_command="$3"
    local timeout_min=$4

    log "--------------------------"

    finished=false
    for ((time=1;time<$timeout_min;time++)); do
        exist_check="$( oc get $kind_name --no-headers=true -n $namespace | wc -l | xargs )"
        log "Waiting for $kind_name in ns $namespace to be present... recheck in $time of $timeout_min mins"

        # display logs
        execlog $display_command

        if [ $exist_check -eq 1 ]; then
            # yes, it's present
            finished=true
            log "Yep, it's present now!"
            break
        else
            echo ""
        fi

        # wait 1 min
        progress-bar 1
    done

    if [[ "$finished" == "false" ]]; then
        log "Hmm, timeout after retrying in $timeout_min mins!"
        exit 99
    fi
}
