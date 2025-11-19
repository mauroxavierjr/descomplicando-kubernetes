# Descomplicando o Kubernetes - Day 01

## DAY-1

# Criação do cluster Kind:
$ kind create cluster --name kind-giropops --config kind-cluster.yaml

# Criação de um pod template utilizando dry-run:
$ kubectl run meu-nginx --image nginx --dry-run=client -oyaml > pod-template-dryrun.yaml

# Criando pod através de um manifest yaml:
$ kubectl apply -f meu-primeiro-pod-working.yaml

# Erros do arquivo meu-primeiro-pod-failed.yaml

# The correct api version is v1 for pods resource in this cluster
apiVersion: v1
kind: Pod
metadata:
  labels:
    # The "_" character is not allowed in Kubernetes labels and names
    run: nginx-giropops
    app: giropops-strigus
  name: nginx-giropops
spec:
  containers:
  - image: nginx
    name: nginx-giropops
    ports:
    - containerPort: 80
    # request must be inside the resources block
    # memory and cpu must not be quoted
    resources: 
      limits: 
        memory: 1024Mi
        cpu: 0.5
      requests:
          memory: 512Mi
          cpu: 0.3
  # DNS policy "ClusterSecond" does not exist in Kubernetes. Valid values are "ClusterFirst", "Default", "None".
  dnsPolicy: ClusterFirst
  restartPolicy: Always

