set -e

export ISTIO_VERSION=1.9.0
export KNATIVE_VERSION=v0.22.0
export KSERVE_VERSION=v0.7.0
export CERT_MANAGER_VERSION=v1.3.0
export KIND_VERSION=v0.11.1
export KIND_ARCH=darwin-amd64 # replace with linux-amd64 or linux-arm64 or darwin-arm64
export NODEPORT=32607
curl -L https://git.io/getLatestIstio | sh -
cd istio-${ISTIO_VERSION}

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${KIND_ARCH}
chmod +x ./kind
cat <<EOF | ./kind create cluster --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: kindest/node:v1.18.19
    kubeadmConfigPatches:
      - |
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            "service-account-issuer": "kubernetes.default.svc"
            "service-account-signing-key-file": "/etc/kubernetes/pki/sa.key"
    extraPortMappings:
    - containerPort: ${NODEPORT}
      hostPort: 8080
    - containerPort: 32608
      hostPort: 5601
    - containerPort: 32609
      hostPort: 9200
    - containerPort: 32610
      hostPort: 9090
EOF

# Create istio-system namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
  labels:
    istio-injection: disabled
EOF

cat << EOF > ./istio-minimal-operator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      proxy:
        autoInject: disabled
      useMCP: false
      # The third-party-jwt is not enabled on all k8s.
      # See: https://istio.io/docs/ops/best-practices/security/#configure-third-party-service-account-tokens
      jwtPolicy: first-party-jwt

  meshConfig:
    accessLogFile: /dev/stdout

  addonComponents:
    pilot:
      enabled: true

  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          service:
            type: NodePort
            ports:
            - port: 80
              name: http2
              nodePort: ${NODEPORT}
              targetPort: 8080
EOF

bin/istioctl manifest apply -f istio-minimal-operator.yaml -y

# Install Knative
kubectl apply --filename https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-crds.yaml
kubectl apply --filename https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-core.yaml
kubectl apply --filename https://github.com/knative/net-istio/releases/download/${KNATIVE_VERSION}/release.yaml

# Install Cert Manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml
kubectl wait --for=condition=available --timeout=600s deployment/cert-manager-webhook -n cert-manager
cd ..
# Install KFServing
KSERVE_CONFIG=kfserving.yaml
if [ ${KSERVE_VERSION:3:1} -gt 6 ]; then KSERVE_CONFIG=kserve.yaml; fi

# Retry inorder to handle that it may take a minute or so for the TLS assets required for the webhook to function to be provisioned
for i in 1 2 3 4 5 ; do kubectl apply -f ~/go/src/github.com/kserve/kserve/install/${KSERVE_VERSION}/${KSERVE_CONFIG} && break || sleep 15; done
# Clean up
rm -rf istio-${ISTIO_VERSION}
rm -f ./kind
