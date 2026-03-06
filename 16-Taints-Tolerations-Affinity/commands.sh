kubectl label nodes kind-control-plane1 region=br-sp datacenter=sp-1
kubectl label nodes kind-control-plane2 region=br-ssa datacenter=ssa-1
kubectl label nodes kind-control-plane3 region=br-ssa datacenter=ssa-2
kubectl label nodes kind-control-plane4 region=br-sp datacenter=sp-2
kubectl label nodes kind-worker1 region=br-sp datacenter=sp-2
kubectl label nodes kind-worker2 region=br-ssa datacenter=ssa-1
kubectl label nodes kind-worker3 region=br-sp datacenter=sp-1
kubectl label nodes kind-worker4 region=br-ssa datacenter=ssa-2

k taint nodes kind-worker maintenance=true:NoSchedule
k taint nodes kind-worker maintenance=true:NoSchedule-
k taint nodes kind-worker3 maintenance=true:NoExecute
k taint nodes kind-worker3 maintenance=true:NoExecute-
k taint nodes kind-worker maintenance=true:PreferNoSchedule
