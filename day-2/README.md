# Descomplicando o Kubernetes
&nbsp;
## DAY-2 - Desafio
&nbsp;
&nbsp;
### Pré-Requisitos
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
&nbsp;
&nbsp;
### Testes do emptyDir
&nbsp;
Objetivo: O manifesto anexo é testar a criação de um pod contendo dois containers.
&nbsp;
01) Container com imagem Alpine responsável por configurar o arquivo index.html no volume compartilhado com o texto "Pod is Working!"
02) Conteiner com imagem do Nginx que vai montar o caminho do index.html no volume compartilhado. Isso vai permitir que o web server utilize a página html customizada.
&nbsp;
&nbsp;
Manifesto: nginx-volume-shared-emptydir.yaml
&nbsp;
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
&nbsp;
&nbsp;
### Testes com limitação de recursos
&nbsp;
Arquivo Manifest: stress-test.yaml.
&nbsp;
Objetivo: Criar um pod com uma definição de limite de recursos e realizar um teste de stress para verificar o comportamento após uma tentativa de ultrapassar o limite permitido de utilização de recursos.
&nbsp;
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: stress-test
  labels:
    app: stress
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
kubectl apply -f stress-test.yaml
pod/stress-test created
```
&nbsp;
&nbsp;
Exibir o pod em execução:
```bash
kubectl get pod -l app=stress
NAME          READY   STATUS    RESTARTS   AGE
stress-test   1/1     Running   0          16s
```
&nbsp;
&nbsp;
Conectando no pod:
```bash
kubectl exec -it stress-test -- sh
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



