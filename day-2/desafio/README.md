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
&nbsp;
### Testes do emptyDir
&nbsp;
Arquivo Manifest: nginx-volume-shared-emptydir.yaml
&nbsp;
Objetivo:
O manifesto anexo é testar a criação de um pod contendo dois containers.
&nbsp;
01) Container com imagem Alpine responsável por configurar o arquivo index.html no volume compartilhado com o texto "Pod is Working!"
02) Conteiner com imagem do Nginx que vai montar o caminho do index.html no volume compartilhado. Isso vai permitir que o web server utilize a página html customizada.
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
Aplicando o arquivo manifesto e criando o pod:
```bash
kubectl apply -f nginx-volume-shared-emptydir.yaml
pod/pod-working created
```
&nbsp;
Verificando se o pod subiu corretamente:
```bash
kubectl apply -f nginx-volume-shared-emptydir.yaml
pod/pod-working created
```
&nbsp;
Verificar o pod em execução:
```bash
kubectl apply -f nginx-volume-shared-emptydir.yaml
pod/pod-working created
```
&nbsp;
Exibir o pod em execução:
```bash
kubectl get pod -l app=webserver
NAME               READY   STATUS    RESTARTS   AGE
nginx-web-server   2/2     Running   0          2m23s
```
&nbsp;
Verificar o ip do pod para testar o acesso http:
```bash
kubectl get pod -l app=webserver -owide
NAME               READY   STATUS    RESTARTS   AGE    IP           NODE               NOMINATED NODE   READINESS GATES
nginx-web-server   2/2     Running   0          5m6s   10.244.2.3   desafio2-worker3   <none>           <none>
```
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










