#!/bin/bash

SLEEP_DURATION=1

function progress-bar {
  local duration
  local columns
  local space_available
  local fit_to_screen  
  local space_reserved

  space_reserved=30                     # reserved width for the message like: | 100% - waiting for 20 mins
  duration=${1}                         # by mins
  duration=$(( duration*60 ));          # convert it to seconds
  if [[ "$__DEBUG__" == "true" ]]; then # this is for debug mode only to accelerate things
    duration=10; 
  fi  
  columns=$(tput cols)
  space_available=$(( columns-space_reserved ))

  if (( duration < space_available )); then 
  	fit_to_screen=1; 
  else 
    fit_to_screen=$(( duration / space_available ));
    fit_to_screen=$((fit_to_screen+1)); 
  fi

  already_done() { for ((done=0; done<(elapsed / fit_to_screen) ; done=done+1 )); do printf "▇"; done }
  remaining() { for (( remain=(elapsed/fit_to_screen) ; remain<(duration/fit_to_screen) ; remain=remain+1 )); do printf " "; done }
  percentage() { printf "| %s%% - waiting for %s mins" $(( ((elapsed)*100)/(duration)*100/100 )) $(( (duration)/60 )); }
  clean_line() { printf "\r"; }

  for (( elapsed=1; elapsed<=duration; elapsed=elapsed+1 )); do
      already_done; remaining; percentage
      sleep "$SLEEP_DURATION"
      clean_line
  done
  clean_line
  printf "\n";
}

function log {
    echo "$(date +"%Y-%m-%d %H:%M:%S %Z"): $@" | tee -a $LOGFILE
}

function logn {
    echo -n "$(date +"%Y-%m-%d %H:%M:%S %Z"): $@" | tee -a $LOGFILE
}

function execlog {
    log "Executing command: $@"
    eval "$@" | tee -a $LOGFILE
}

function validate_storageclass {
    echo "Validating storage class: $1"
    if [ $(oc get sc $1 --no-headers | wc -l) -le 0 ]; then
        echo "Storage class $1 is not valid."
        exit 999
    else
        echo "Storage class $1 exists."
    fi
}
