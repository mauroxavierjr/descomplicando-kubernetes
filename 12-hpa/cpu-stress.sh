kubectl run -i --tty load-generator --image=busybox /bin/sh

while true; do wget -q -O- http://nginx-deployment.default.svc.cluster.local; done