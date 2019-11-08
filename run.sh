#!/bin/sh

#chartify="$WERCKER_STEP_ROOT/go/bin/chartify"
helm="$WERCKER_STEP_ROOT/helm"
kubectl="$WERCKER_STEP_ROOT/kubectl"

display_chartify_version() {
  info "Running chartify version:"
  "$chartify" version
  echo ""
}

display_helm_kubectl_version() {
  info "Running kubectl version:"
  "$kubectl" version --client
  echo ""
  info "Running helm version:"
  "$helm" version --client
  echo ""
}

# This is used to create a kubeconfig file if the user passed server+token
# This is also used by helm calls
generate_kubeconfig() {
    master="$1"
    token="$2"
    clusterId="$3"
    kubeconfig_path="$4"

    echo "Write config to file using master: ${master}, clusterId: ${clusterId}"
    echo "
    apiVersion: v1
    clusters:
      - cluster:
          insecure-skip-tls-verify: true
          server: ${master}
        name: cluster-${clusterId}
    contexts:
      - context:
          cluster: cluster-${clusterId}
          user: user-${clusterId}
        name: context-${clusterId}
    current-context: context-${clusterId}
    kind: \"\"
    users:
      - name: user-${clusterId}
        user:
              token: ${token}
    " > "$kubeconfig_path"

}

main() {
  display_helm_kubectl_version
  display_chartify_version
  
  kubeconfig="$KUBECONFIG_TEXT"
  server="$WERCKER_STEP_AURA_SERVER"
  token="$WERCKER_STEP_AURA_TOKEN"
  chartify_cmd="$WERCKER_HELM_CHART_GENERATE_COMMAND"
  cmd="cluster-info"
  helm_cmd="$WERCKER_HELM_COMMAND"

  helm_args=
  # release-name
  if [ $helm_cmd == "install" ]; then 
    if [ -n "$WERCKER_HELM_RELEASE_NAME" ]; then
      helm_args="$helm_args --name=\"$WERCKER_HELM_RELEASE_NAME\""
    fi
    # release-namespace
    if [ -n "$WERCKER_HELM_RELEASE_NAMESPACE" ]; then
      helm_args="$helm_args --namespace=\"$WERCKER_HELM_RELEASE_NAMESPACE\""
    fi
  else
    if [ -n "$WERCKER_HELM_RELEASE_NAME" ]; then
      helm_args="$helm_args \"$WERCKER_HELM_RELEASE_NAME\""
    fi
  fi

  # repo
  if [ -n "$WERCKER_HELM_REPO" ]; then
    helm_args="$helm_args --repo=\"$WERCKER_HELM_REPO\""
    helm_args="$helm_args \"$WERCKER_HELM_CHART_NAME\""
  else
    if [ -n "$WERCKER_HELM_CHART_NAME" ]; then
      helm_args="$helm_args \"$WERCKER_HELM_CHART_NAME\""
      $WERCKER_STEP_ROOT/envsubst < "$WERCKER_HELM_CHART_NAME/values.yaml" > "$HOME/values.yaml"
      helm_args="$helm_args -f \"$HOME/values.yaml\""
      cat $HOME/values.yaml
    fi 
  fi

 # values file
  if [ -n "$WERCKER_HELM_VALUES_FILE" ]; then
    $WERCKER_STEP_ROOT/envsubst < "$WERCKER_HELM_VALUES_FILE" > "$HOME/values.yaml"
    helm_args="$helm_args -f \"$HOME/values.yaml\""
fi 
  # Global args
  global_args=
  raw_global_args="$WERCKER_HELM_CHART_GENERATE_RAW_GLOBAL_ARGS"
  
  # token
  if [ -n "$WERCKER_HELM_TOKEN" ]; then
    global_args="$global_args --token=\"$WERCKER_HELM_TOKEN\""
  fi

  # username
  if [ -n "$WERCKER_HELM_USERNAME" ]; then
    global_args="$global_args --username=\"$WERCKER_HELM_USERNAME\""
  fi

  # password
  if [ -n "$WERCKER_HELM_PASSWORD" ]; then
    global_args="$global_args --password=\"$WERCKER_HELM_PASSWORD\""
  fi

  # server
  if [ -n "$WERCKER_HELM_SERVER" ]; then
    global_args="$global_args --server=\"$WERCKER_HELM_SERVER\""
  fi
  
  # insecure-skip-tls-verify
  if [ -n "$WERCKER_HELM_INSECURE_SKIP_TLS_VERIFY" ]; then
    global_args="$global_args --insecure-skip-tls-verify=\"$WERCKER_HELM_INSECURE_SKIP_TLS_VERIFY\""
  fi

  # certificate-authority
  if [ -n "$WERCKER_HELM_CERTIFICATE_AUTHORITY" ]; then
    global_args="$global_args --certificate-authority=\"$WERCKER_HELM_CERTIFICATE_AUTHORITY\""
  fi
  
  # client-certificate
  if [ -n "$WERCKER_HELM_CLIENT_CERTIFICATE" ]; then
    global_args="$global_args --client-certificate=\"$WERCKER_HELM_CLIENT_CERTIFICATE\""
  fi
  
  # client-key
  if [ -n "$WERCKER_HELM_CLIENT_KEY" ]; then
    global_args="$global_args --client-key=\"$WERCKER_HELM_CLIENT_KEY\""
  fi

  # token
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_CHART_GENERATE_TOKEN" ]; then
  #  global_args="$global_args --token=\"$WERCKER_HELM_CHART_GENERATE_TOKEN\""
  #fi

  # username
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_USERNAME" ]; then
  #  global_args="$global_args --username=\"$WERCKER_HELM_CHART_GENERATE_USERNAME\""
  #fi

  # password
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_PASSWORD" ]; then
  #  global_args="$global_args --password=\"$WERCKER_HELM_CHART_GENERATE_PASSWORD\""
  #fi

  # server
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_SERVER" ]; then
  #  global_args="$global_args --server=\"$WERCKER_HELM_CHART_GENERATE_SERVER\""
  #fi

  # insecure-skip-tls-verify
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_INSECURE_SKIP_TLS_VERIFY" ]; then
  #  global_args="$global_args --insecure-skip-tls-verify=\"$WERCKER_HELM_CHART_GENERATE_INSECURE_SKIP_TLS_VERIFY\""
  #fi
    # certificate-authority
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_CERTIFICATE_AUTHORITY" ]; then
  #  global_args="$global_args --certificate-authority=\"$WERCKER_HELM_CHART_GENERATE_CERTIFICATE_AUTHORITY\""
  #fi
    # client-certificate
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_CLIENT_CERTIFICATE" ]; then
  #  global_args="$global_args --client-certificate=\"$WERCKER_HELM_CHART_GENERATE_CLIENT_CERTIFICATE\""
  #fi
    # client-key
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_CLIENT_KEY" ]; then
  #  global_args="$global_args --client-key=\"$WERCKER_HELM_CHART_GENERATE_CLIENT_KEY\""
  #fi

  #sudo mkdir -p "$HOME/.kube"
  ROOT_KUBECONFIG_PATH="/root/.kube/config"
  $WERCKER_STEP_ROOT/envsubst < "$WERCKER_STEP_ROOT/config" > "$HOME/.kube/config"
  
  if [ ! "${KUBECONFIG_TEXT}" = "" ] ; then
     echo "Using supplied kubeconfig"

     # wercker maps newlines to "\n" all on a single line
     echo "${KUBECONFIG_TEXT}" | sed 's/\\n/\/g' >> ${ROOT_KUBECONFIG_PATH}

  else
     echo "Generating kubeconfig"
     generate_kubeconfig "$server" "$token" "cluster1" "${ROOT_KUBECONFIG_PATH}"
  fi

  echo "Using kubeconfig:"
  cat "${ROOT_KUBECONFIG_PATH}"
  
  # export KUBECONFIG= $HOME/.kube/config
  info "Connecting to the Cluster as specified in kubeconfig"
  $kubectl cluster-info --kubeconfig "$HOME/.kube/config"

  # Global args
  #chartify_args=
  #chartify_cmd=
  global_args="$global_args --insecure-skip-tls-verify=\"true\""
  
  # chart-name
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_CHART_NAME" ]; then
  #      chartify_args="$chartify_args \"WERCKER_HELM_CHART_GENERATE_CHART_NAME\""
  #fi

  # chart-dir
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_CHART_DIR" ]; then
  #      chartify_args="$chartify_args --chart-dir=\"WERCKER_HELM_CHART_GENERATE_CHART_DIR\""
  #fi

  # configmaps
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_CONFIGMAPS" ]; then
  #      chartify_args="$chartify_args --configmaps=\"WERCKER_HELM_CHART_GENERATE_CONFIGMAPS\""
  #fi

  # daemons
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_DAEMONS" ]; then
  #      chartify_args="$chartify_args --daemons=\"WERCKER_HELM_CHART_GENERATE_DAEMONS\""
  #fi

  # deployments
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_DEPLOYMENTS" ]; then
  #      chartify_args="$chartify_args --deployments=\"WERCKER_HELM_CHART_GENERATE_DEPLOYMENTS\""
  #fi

  # jobs
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_JOBS" ]; then
  #      chartify_args="$chartify_args --jobs=\"WERCKER_HELM_CHART_GENERATE_JOBS\""
  #fi
#
  # kube-dir
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_KUBE_DIR" ]; then
  #      chartify_args="$chartify_args --kube-dir=\"WERCKER_HELM_CHART_KUBE_DIR\""
  #fi

  # pods
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_PODS" ]; then
  #      chartify_args="$chartify_args --pods=\"WERCKER_HELM_CHART_PODS\""
  #fi

  # pvcs
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_PVCS" ]; then
  #      chartify_args="$chartify_args --pvcs=\"WERCKER_HELM_CHART_PVCS\""
  #fi

  # pvs
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_PVS" ]; then
  #      chartify_args="$chartify_args --pvs=\"WERCKER_HELM_CHART_PVS\""
  #fi

  # rcs
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_RCS" ]; then
  #      chartify_args="$chartify_args --rcs=\"WERCKER_HELM_CHART_RCS\""
  #fi

  # replicasets
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_REPLICASETS" ]; then
  #      chartify_args="$chartify_args --replicasets=\"WERCKER_HELM_CHART_REPLICASETS\""
  #fi

  # secrets
  if [ -n "$WERCKER_HELM_CHART_GENERATE_SECRETS" ]; then
        chartify_args="$chartify_args --secrets=\"WERCKER_HELM_CHART_SECRETS\""
  fi

  # services
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_SERVICES" ]; then
  #      chartify_args="$chartify_args --services=\"WERCKER_HELM_CHART_SERVICES\""
  #fi

  # statefulsets
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_STATEFULSETS" ]; then
  #      chartify_args="$chartify_args --statefulsets=\"WERCKER_HELM_CHART_STATEFULSETS\""
  #fi

  # preserve-name
  #if [ -n "$WERCKER_HELM_CHART_GENERATE_PRESERVE_NAME" ]; then
  #      chartify_args="$chartify_args --preserve-name=\"WERCKER_HELM_CHART_PRESERVE_NAME\""
  #fi

  #info "executing chartify command"
  #$chartify $chartify_cmd $chartify_args
  
  info "Executing Helm Command"
  echo "$helm" "$helm_cmd" "$helm_args" 
  eval "$helm" "$helm_cmd" "$helm_args" 
}

main;
