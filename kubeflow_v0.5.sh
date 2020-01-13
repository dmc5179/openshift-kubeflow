#!/bin/bash

# Make sure to install Ksonnet first
# It will be required later

NAMESPACE=kubeflow

oc new-project ${NAMESPACE}
oc project ${NAMESPACE}

# Set permissions for service accounts

oc adm policy add-scc-to-user anyuid -z ambassador -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z argo -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z argo-ui -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z builder -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z centraldashboard -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z default -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z deployer -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z jupyter -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z jupyter-notebook -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z jupyter-web-app -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z katib-ui -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z meta-controller-service -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z metrics-collector -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ml-pipeline -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ml-pipeline-persistenceagent -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ml-pipeline-scheduledworkflow -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ml-pipeline-ui -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z ml-pipeline-viewer-crd-service-account -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z notebook-controller -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z pipeline-runner -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z profiles -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z pytorch-operator -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z spartakus -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z studyjob-controller -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z tf-job-dashboard -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z tf-job-operator -n${NAMESPACE}
oc adm policy add-scc-to-user anyuid -z vizier-core -n${NAMESPACE}


export KUBEFLOW_SRC=kubeflow
export KUBEFLOW_TAG=v0.5-branch
mkdir ${KUBEFLOW_SRC}
cd ${KUBEFLOW_SRC}
curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
export KFAPP=openshift
scripts/kfctl.sh init ${KFAPP} --platform none
pushd openshift
../scripts/kfctl.sh generate k8s
../scripts/kfctl.sh apply k8s


#NOTE!!!!
# This is manual at the moment. It is very annoying
# There is probably a way to do with with the oc CLI
###################
# To enable the argo-ui change the argo-ui deployment
# Then create a route to it once the pod restart
# - env:
#            - name: ARGO_NAMESPACE
#              valueFrom:
#                fieldRef:
#                  apiVersion: v1
#                  fieldPath: metadata.namespace
#            - name: IN_CLUSTER
#              value: 'true'
#            - name: ENABLE_WEB_CONSOLE  # Change starts here
#              value: 'false'            #
#            - name: BASE_HREF           #
#              value: /                  # Change ends here
###################



# Need RBAC roles for Argo to work
oc apply -f argo-role.yaml -n kubeflow

#It is also necessary to give additional (privileged) permissions to an argo role using the following command:
oc adm policy add-scc-to-user privileged -z argo -nkubeflow

# Download the argo client
#wget https://github.com/argoproj/argo/releases/download/v2.3.0/argo-linux-amd64

# Download the minio client
#wget https://dl.min.io/server/minio/release/linux-amd64/minio

# Configure the minio CLI
#mc config host add minio http://[your-minio-service-URL] minio minio123

# Kubeflow is typically tested used GKE, which is significantly less strict compared to OpenShift
oc apply -f tfjobs-role.yaml -n kubeflow

# Kubeflow is typically tested used GKE, which is significantly less strict compared to OpenShift
oc apply -f studyjobs-role.yaml -n kubeflow

# Study job for Katib example
# oc create -f https://raw.githubusercontent.com/kubeflow/katib/master/examples/random-example.yaml

# If you want to serve ML Models from S3 you need to provide a secret to access AWS
# oc apply -f aws_access.yaml -n kubeflow
# Or you can use minio
# mc cp saved_model.pb minio/serving/mnist/1/saved_model.pb

oc adm policy add-scc-to-user privileged -nkubeflow -z pipeline-runner

# Model DB is not part of the standard kubeflow install but it can be installed using
# ks generate modeldb modeldb
# ks apply default -c modeldb



