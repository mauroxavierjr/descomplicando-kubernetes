# Descomplicando o Kubernetes - DAY-2 - Desafio
&nbsp;
-------------------------------------------------------------------------------------------------------------------
## 1 - Pré-Requisitos
&nbsp;
Criando Cluster kind:
```bash
kind create cluster --config kind-cluster-creation.yaml --name desafio2
```
&nbsp;
Kind cluster yaml:
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
```
&nbsp;
&nbsp;
-------------------------------------------------------------------------------------------------------------------
## 2 - Testes do emptyDir
&nbsp;
Objetivo: O manifesto anexo é testar a criação de um pod contendo dois containers.
&nbsp;
01) Container com imagem Alpine responsável por configurar o arquivo index.html no volume compartilhado com o texto "Pod is Working!"
02) Conteiner com imagem do Nginx que vai montar o caminho do index.html no volume compartilhado. Isso vai permitir que o web server utilize a página html customizada.
&nbsp;
&nbsp;
### nginx-volume-shared-emptydir.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-web-server
  labels:
    status: webserver
spec:
  volumes:
  - name: shared-volume
    emptyDir:
      sizeLimit: 256Mi
  containers:
  - name: change-index-html
    image: alpine:latest
    args:
      - sh
      - -c
      - echo '<h1>Pod is Working!</h1>' > /usr/share/nginx/html/index.html; sleep 36000
    volumeMounts:
    - name: shared-volume
      mountPath: /usr/share/nginx/html
    resources:
      limits:
        memory: "128Mi"
        cpu: "0.3"
      requests:
        memory: "64Mi"
        cpu: "0.1"
  - name: nginx
    image: nginx:latest
    volumeMounts:
    - name: shared-volume
      mountPath: /usr/share/nginx/html
    ports:
    - containerPort: 80
    resources:
      limits:
        memory: "128Mi"
        cpu: "0.3"
      requests:
        memory: "64Mi"
        cpu: "0.1"
```
&nbsp;
&nbsp;
Aplicando o arquivo manifesto e criando o pod:
```bash
kubectl apply -f nginx-volume-shared-emptydir.yaml
pod/nginx-web-server created
```
&nbsp;
&nbsp;
Exibir o pod em execução:
```bash
kubectl get pod -l app=webserver
NAME               READY   STATUS    RESTARTS   AGE
nginx-web-server   2/2     Running   0          2m23s
```
&nbsp;
&nbsp;
Verificar o ip do pod para testar o acesso http:
```bash
kubectl get pod -l app=webserver -owide
NAME               READY   STATUS    RESTARTS   AGE    IP           NODE               NOMINATED NODE   READINESS GATES
nginx-web-server   2/2     Running   0          5m6s   10.244.2.3   desafio2-worker3   <none>           <none>
```
&nbsp;
&nbsp;
Conectando no container Alpine e testando o shared volume e o acesso ao webserver:
```bash
kubectl exec -it nginx-web-server -c change-index-html -- sh
/ # apk add curl
OK: 12 MiB in 25 packages
/ # cat /usr/share/nginx/html/index.html
<h1>Pod is Working!</h1>
/ # curl http://10.244.2.3
<h1>Pod is Working!</h1>
```
&nbsp;
&nbsp;
-------------------------------------------------------------------------------------------------------------------
## 3 - Testes com limitação de recursos
&nbsp;
Objetivo: Criar um pod com uma definição de limite de recursos e realizar um teste de stress para verificar o comportamento após uma tentativa de ultrapassar o limite permitido de utilização de recursos. Para esse cenário vou utilizar dois tipos de manifestos diferentes:
&nbsp;
### stress-test-sandbox
Manifesto onde vou iniciar o pod com sucesso e realizar o testes de stress conectando no container através do terminal.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: stress-test-sandbox
  labels:
    app: stress-test-sandbox
spec:
  containers:
  - name: ubuntu
    image: ubuntu:latest
    args:
    - sleep
    - infinity
    resources:
      limits:
        memory: "256Mi"
        cpu: "0.5"
      requests:
        memory: "128Mi"
        cpu: "0.3"
```
&nbsp;
&nbsp;
Aplicando o arquivo manifesto e criando o pod:
```bash
kubectl apply -f stress-test-sandbox.yaml
pod/stress-test-test-sandbox created
```
&nbsp;
&nbsp;
Exibir o pod em execução:
```bash
kubectl get pod -l app=stress
NAME          READY   STATUS    RESTARTS   AGE
stress-test-sandbox   1/1     Running   0          16s
```
&nbsp;
&nbsp;
Conectando no pod:
```bash
kubectl exec -it stress-test-sandbox -- sh
```
&nbsp;
&nbsp;
Instalando pacote da aplicação para realizar o teste de stress (stress):
```bash
apt update
apt install -y stress
```
&nbsp;
&nbsp;
Executando a utilização de 200M de mem´roria no stress test. Esse consumo é possível por conta do limites está definido como 256M.
```bash
stress --vm 1 --vm-bytes 200M
stress: info: [177] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
```
&nbsp;
&nbsp;
Agora ao tentar utilizar 280M é exibido um erro:
```bash
stress --vm 1 --vm-bytes 280M
stress: info: [179] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
stress: FAIL: [179] (425) <-- worker 180 got signal 9
stress: WARN: [179] (427) now reaping child worker processes
stress: FAIL: [179] (461) failed run completed in 0s
```
&nbsp;
&nbsp;
### stress-test-error
Manifesto onde vou similar uma falha de inicialização do pod devido a necessidade de consumo de recursos acima dom limite ocorrer na inicialização.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: stress-test-error
  labels:
    app: stress-test-error
spec:
  containers:
    - name: stress-test-error
      image: polinux/stress
      command: ["stress"]
      args: ["--vm", "1", "--vm-bytes", "300M", "--vm-hang", "1"]
      resources:
        limits:
          memory: "256Mi"
          cpu: "0.5"
        requests:
          memory: "128Mi"
          cpu: "0.3"
```
&nbsp;
&nbsp;
Aplicando o arquivo manifesto e criando o pod:
```bash
kubectl apply -f stress-test-error.yaml
pod/stress-test-error created
```
&nbsp;
&nbsp;
Exibir o pod em execução. Aqui estou utilizando o arumento -w para acompanhar a atualização de status do pod. É possível reparar que ele está constantemente tentando iniciar sem sucesso.
```bash
kubectl get pods stress-test-error -w
NAME                READY   STATUS             RESTARTS     AGE
stress-test-error   0/1     CrashLoopBackOff   1 (4s ago)   7s
stress-test-error   0/1     Error              2 (14s ago)   17s
stress-test-error   0/1     CrashLoopBackOff   2 (12s ago)   29s
stress-test-error   0/1     Error              3 (27s ago)   44s
stress-test-error   0/1     CrashLoopBackOff   3 (10s ago)   54s
stress-test-error   0/1     Error              4 (50s ago)   94s
stress-test-error   0/1     CrashLoopBackOff   4 (12s ago)   106s
stress-test-error   0/1     Error              5 (84s ago)   2m58s
stress-test-error   0/1     CrashLoopBackOff   5 (<invalid> ago)   3m9s
stress-test-error   0/1     Error              6 (2m44s ago)       10m
stress-test-error   0/1     CrashLoopBackOff   6 (14s ago)         10m
stress-test-error   1/1     Running            7 (73s ago)         11m
stress-test-error   0/1     Error              7 (74s ago)         11m
stress-test-error   0/1     CrashLoopBackOff   7 (16s ago)         11m
```
&nbsp;
&nbsp;
Aqui é possível acompanhar o que é exibido nos eventos ao utilizar o comando describe.
```bash
kubectl describe pod stress-test-error
Name:             stress-test-error
Namespace:        default
Priority:         0
Service Account:  default
Node:             kind-worker3/172.19.0.3
Start Time:       Thu, 27 Nov 2025 21:28:41 -0300
Labels:           app=stress-test-error
Annotations:      <none>
Status:           Running
IP:               10.244.3.5
IPs:
  IP:  10.244.3.5
Containers:
  stress-test-error:
    Container ID:  containerd://42f876294b6ee58377144c230e896212ca1a2de0cdadaed3ab85f35ded8d105f
    Image:         polinux/stress
    Image ID:      docker.io/polinux/stress@sha256:b6144f84f9c15dac80deb48d3a646b55c7043ab1d83ea0a697c09097aaad21aa
    Port:          <none>
    Host Port:     <none>
    Command:
      stress
    Args:
      --vm
      1
      --vm-bytes
      300M
      --vm-hang
      1
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Thu, 27 Nov 2025 21:30:15 -0300
      Finished:     Thu, 27 Nov 2025 21:30:15 -0300
    Ready:          False
    Restart Count:  4
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:        300m
      memory:     128Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-pzsp8 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       False
  ContainersReady             False
  PodScheduled                True
Volumes:
  kube-api-access-pzsp8:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  112s                default-scheduler  Successfully assigned default/stress-test-error to kind-worker3
  Normal   Pulled     111s                kubelet            Successfully pulled image "polinux/stress" in 1.111s (1.111s including waiting). Image size: 4041495 bytes.
  Normal   Pulled     109s                kubelet            Successfully pulled image "polinux/stress" in 1.055s (1.055s including waiting). Image size: 4041495 bytes.
  Normal   Pulled     96s                 kubelet            Successfully pulled image "polinux/stress" in 1.025s (1.025s including waiting). Image size: 4041495 bytes.
  Normal   Pulled     69s                 kubelet            Successfully pulled image "polinux/stress" in 1.032s (1.032s including waiting). Image size: 4041495 bytes.
  Normal   Pulling    20s (x5 over 112s)  kubelet            Pulling image "polinux/stress"
  Normal   Created    19s (x5 over 111s)  kubelet            Created container: stress-test-error
  Normal   Pulled     19s                 kubelet            Successfully pulled image "polinux/stress" in 1.123s (1.123s including waiting). Image size: 4041495 bytes.
  Normal   Started    18s (x5 over 111s)  kubelet            Started container stress-test-error
  Warning  BackOff    6s (x10 over 108s)  kubelet            Back-off restarting failed container stress-test-error in pod stress-test-error_default(75f7fbbe-a00d-43e2-b768-a5495662eb4f)
```
&nbsp;
&nbsp;
Nos logs é possível ver o erro retornado após o comando stress tentar consumir mais recuros do que foi definido nos limites.
```bash
kubectl logs stress-test-error
stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
stress: FAIL: [1] (415) <-- worker 11 got signal 9
stress: WARN: [1] (417) now reaping child worker processes
stress: FAIL: [1] (421) kill error: No such process
stress: FAIL: [1] (451) failed run completed in 0s
```
