kind delete cluster

./quick_install_kind.sh

# prometheus
kustomize build docs/samples/metrics-and-monitoring/prometheus-operator | kubectl apply -f -
kubectl wait --for condition=established --timeout=120s crd/prometheuses.monitoring.coreos.com
kubectl wait --for condition=established --timeout=120s crd/servicemonitors.monitoring.coreos.com
kustomize build docs/samples/metrics-and-monitoring/prometheus | kubectl apply -f -

kubectl apply -f ~/Developer/kserve-tutorial/prom-svc.yaml

# knative eventing
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.22.0/eventing-crds.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.22.0/eventing-core.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.22.0/in-memory-channel.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.22.0/mt-channel-broker.yaml

kubectl apply -f ~/go/src/github.com/kserve/kserve/docs/samples/logger/knative-eventing/broker.yaml

kubectl apply -f ~/Developer/kserve-tutorial/trigger.yaml

# k patch cm inferenceservice-config -p... "defaultUrl": "http://broker-ingress.knative-eventing.svc.cluster.local/default/default"

# elasticsearch
kubectl create -f https://download.elastic.co/downloads/eck/1.8.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/1.8.0/operator.yaml
kubectl apply -f ~/Developer/kserve-tutorial/es.yaml

cd ~/go/src/github.com/theofpa/event-es/

ko apply -f event-service-ko.yaml

kubectl apply -f ~/Developer/kserve-tutorial/models.yaml

kubectl apply -f ~/Developer/kserve-tutorial/kserve_feast/feast.yaml
#kubectl port-forward svc/feast 6566:6566
#curl -X POST "http://localhost:6566/get-online-features" -d '{    "features": [      "driver_hourly_stats:conv_rate",      "driver_hourly_stats:acc_rate",      "driver_hourly_stats:avg_daily_trips"    ],    "entities": {      "driver_id": [1001, 1002, 1003]    }  }' | jq
