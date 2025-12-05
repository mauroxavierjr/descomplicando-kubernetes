## Deployments e Estratégias de Rolout
&nbsp;
## Deployment
No Kubernetes um Deployment é um objeto que representa uma aplicação. Ele é responsável por gerenciar os Pods que compõem uma aplicação. Um Deployment é uma abstração que nos permite atualizar os Pods e também fazer o rollback para uma versão anterior caso algo dê errado.

Quando criamos um Deployment é possível definir o número de réplicas que queremos que ele tenha. O Deployment irá garantir que o número de Pods que ele está gerenciando seja o mesmo que o número de réplicas definido. Se um Pod morrer, o Deployment irá criar um novo Pod para substituí-lo. Isso ajuda demais na disponibilidade da aplicação.

Um Deployment é declarativo, ou seja, nós definimos o estado desejado e o Deployment irá fazer o que for necessário para que o estado atual seja igual ao estado desejado.

Quando criamos um Deployment, nós automaticamente estamos criando um ReplicaSet. O ReplicaSet é um objeto que é responsável por gerenciar os Pods para o Deployment, já o Deployment é responsável por gerenciar os ReplicaSets.Como eu disse, um ReplicaSet é um objeto que é criado automaticamente pelo Deployment, mas nós podemos criar um ReplicaSet manualmente caso necessário. 
&nbsp;
## Criando Manifesto de um Deployment
&nbsp;
```yaml
# Definição do tipo de objeto e versão da API
apiVersion: apps/v1
kind: Deployment
# Definição das labels que serão adicionadas ao Deployment
metadata:
  labels:
    app: nginx-deployment
  name: nginx-deployment
# Definição da quantidade de réplicas que o deployment vai ter
spec:
  replicas: 1
# Definiçõa do seletor que o Deployment vai utilizar. No caso o Deployment vai gerenciar os Pods que possuírem essa label
  selector:
    matchLabels:
      app: nginx-deployment
# Definição da estratégia de rollout. No caso está em branco, sendo assim será utilizada a padrão Rolling Update
  strategy: {}
# Definição das configuração de configuração do Pod
  template:
    metadata:
      labels:
        app: nginx-deployment
    spec:
      containers:
      - image: nginx
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: 256Mi
          requests:
            cpu: "0.25"
            memory: 128Mi
```
&nbsp;
## Aplicando um Deployment
&nbsp;
Comando utilizado para configurar um Deployment através do arquivo manifesto.
```bash
$ kubectl apply -f deployment.yaml
```
&nbsp;
## Conferindo a Crição do Deployment
Exibindo o Deployment criado e em execução. Detalhe para a label configurada:
```bash
$ kubectl get deployment nginx-deployment --show-labels
NAME               READY   UP-TO-DATE   AVAILABLE   AGE     LABELS
nginx-deployment   1/1     1            1           7m10s   app=nginx-deployment
```
&nbsp;
Exibindo o Deployment através de sua label:
```bash
$ kubectl get deployment -l app=nginx-deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   1/1     1            1           51m
```
&nbsp;
## Como verificar os Pods que o Deployment está gerenciando?
Definimos quais Pods o Deployment deve gerenciar através da definição do matchLabels no manifesto. Sendo assim se buscar os Pods pela label é possível identificar quais estão sendo gerenciados.
```bash
$ kubectl get pods -l app=nginx-deployment
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-58996d66df-jjt5k   1/1     Running   0          54
```
&nbsp;
## Como verificar o ReplicaSet que o Deployment está gerenciando?
Da mesma forma que utilizamos a label para identificar o Pods gerenciado pelo Deployment, o mesmo pode ser feito para o ReplicaSet:
```bash
$ kubectl get replicaset -l app=nginx-deployment
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-58996d66df   1         1         1       56m
```
&nbsp;
## Como verificar os detalhes de um Deployment?
O describe é um parametro usado para verificar informações mais detalhadas a respeito de objetos do Kubernetes.
```bash
$ kubectl describe deployment nginx-deployment
```
Seguem as informações que podem ser encontradas na saída do comando:
*  O nome do Deployment
*  O Namespace que o Deployment está
*  Os labels que o Deployment possui
*  A quantidade de réplicas que o Deployment possui
*  O selector que o Deployment utiliza para identificar os Pods que ele irá gerenciar
*  Limites de CPU e memória que o Deployment irá utilizar
*  O pod template que o Deployment irá utilizar para criar os Pods
*  A estratégia que o Deployment irá utilizar para atualizar os Pods
*  O ReplicaSet que o Deployment está gerenciando
*  Os eventos que aconteceram no Deployment
&nbsp;
Exemplo da saída do comando do Deployment nginx-deployment.yaml:
```yaml
Name:                   nginx-deployment
Namespace:              default
CreationTimestamp:      Fri, 05 Dec 2025 15:12:01 -0300
Labels:                 app=nginx-deployment
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=nginx-deployment
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx-deployment
  Containers:
   nginx:
    Image:      nginx
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:         250m
      memory:      128Mi
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-deployment-58996d66df (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  60m   deployment-controller  Scaled up replica set nginx-deployment-58996d66df from 0 to 1
```
&nbsp;
## Como atualizar um Deployment?
O comando apply ele é utilizado para criar novos Deployments, mas também podemos utilizar ele quando queremos atualizar as configurações de um Deployment em execução. Para isso vou alterar a quantidade de réplicas doDeployment de 1 para 3 e vamos avaliar o resultado.
&nbsp;
Quantidade de réplicas alterada no aquivo manifesto:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deployment
  name: nginx-deployment
spec:
  replicas: 3 # Alterado de 1 para 3
  selector:
    matchLabels:
      app: nginx-deployment
```
&nbsp;
Execuando o apply para aplicar as alterações:
```bash
$ kubectl apply -f nginx-deployment.yaml 
deployment.apps/nginx-deployment configured
```
&nbsp;
Exibindo a nova quantidade de réplicas:
```bash
$ kubectl get pods -l app=nginx-deployment
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-58996d66df-4f9x9   1/1     Running   0          64s
nginx-deployment-58996d66df-jjt5k   1/1     Running   0          72m
nginx-deployment-58996d66df-kdhmk   1/1     Running   0          64s
```
&nbsp;
## Estratégias de Atualização
Na criação do arquivo manifesto nginx-deployment.yaml definimos o strategy como nulo. Mas é possível trabalhar com os modelos RollingUpdate ou Recreate. Não definir alguma opção faz com que o Deployment utilize a estratégia padrão RollingUpdate.
&nbsp;
### Estratégia RollingUpdate
A estratégia RollingUpdate é a estratégia de atualização padrão do Kubernetes, ela é utilizada para atualizar os Pods de um Deployment de forma gradual, ou seja, ela atualiza um Pod por vez, ou um grupo de Pods por vez.
&nbsp;
Nós podemos definir como será a atualização dos Pods, por exemplo, podemos definir a quantidade máxima de Pods que podem ficar indisponíveis durante a atualização, ou podemos definir a quantidade máxima de Pods que podem ser criados durante a atualização.
&nbsp;
Vamos utilizar o manifesto nginx-deployment-rollingupdate.yaml para esses testes.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deployment-rollingupdate
  name: nginx-deployment-rollingupdate
spec:
  replicas: 10
  selector:
    matchLabels:
      app: nginx-deployment-rollingupdate
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 2
  template:
    metadata:
      labels:
        app: nginx-deployment-rollingupdate
    spec:
      containers:
      - image: nginx
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: 256Mi
          requests:
            cpu: "0.25"
            memory: 128Mi
```
&nbsp;
Vamos detalhar as opções novas que incluímos no manifesto:

*  maxSurge: define a quantidade máxima de Pods que podem ser criados a mais durante a atualização, ou seja, durante o processo de atualização, nós podemos ter 1 Pod a mais do que o número de Pods definidos no Deployment. Isso é útil pois agiliza o processo de atualização, pois o Kubernetes não precisa esperar que um Pod seja atualizado para criar um novo Pod.
  
*  maxUnavailable: define a quantidade máxima de Pods que podem ficar indisponíveis durante a atualização, ou seja, durante o processo de atualização, nós podemos ter 1 Pod indisponível por vez. Isso é útil pois garante que o serviço não fique indisponível durante a atualização.

* type: define o tipo de estratégia de atualização que será utilizada, no nosso caso, nós estamos utilizando a estratégia RollingUpdate.

Sendo assim no nosso teste estamos falando para o Kubernetes que queremos criar até 1 Pod a mais durante a atualização e que ele termine de dois em dois Pods durante esse processo.

Para realizar o teste vamos primeiro criar os 10 Pods.

```bash
$ kubectl apply -f nginx-deployment-rollingupdate.yaml 
deployment.apps/nginx-deployment-rollingupdate created
```

Agora veja o comportamento do update quando mudamos a configuração do manifesto. No caso alteramos a versão do Nginx e podemos ver que o Kubernetes segue a nossa estratégia de atualização dos pods.

```bash
$ kubectl get pods
NAME                                              READY   STATUS              RESTARTS   AGE
nginx-deployment-rollingupdate-664484c8c-8znsg    1/1     Running             0          4m55s
nginx-deployment-rollingupdate-664484c8c-fnxll    1/1     Running             0          4m55s
nginx-deployment-rollingupdate-664484c8c-jfzlg    0/1     ContainerCreating   0          4m48s
nginx-deployment-rollingupdate-664484c8c-qnjz8    0/1     ContainerCreating   0          4m48s
nginx-deployment-rollingupdate-664484c8c-qs548    0/1     ContainerCreating   0          4m55s
nginx-deployment-rollingupdate-857f8dd874-25f5g   1/1     Running             0          8m5s
nginx-deployment-rollingupdate-857f8dd874-ghtp2   1/1     Running             0          8m5s
nginx-deployment-rollingupdate-857f8dd874-kxv96   1/1     Terminating         0          8m5s
nginx-deployment-rollingupdate-857f8dd874-l5vm4   1/1     Running             0          8m5s
nginx-deployment-rollingupdate-857f8dd874-lqhzp   1/1     Running             0          8m5s
nginx-deployment-rollingupdate-857f8dd874-ph26w   1/1     Running             0          8m5s
nginx-deployment-rollingupdate-857f8dd874-sjt5s   1/1     Running             0          8m5s
nginx-deployment-rollingupdate-857f8dd874-wn5sv   1/1     Terminating         0          8m5s
```

O comando abaixo pode ser utilizado para verificar o status do Deployment.

```bash
$ kubectl rollout status deployment nginx-deployment-rollingupdate 
deployment "nginx-deployment-rollingupdate" successfully rolled out
```

Se o deployments estiver em andamento essa será a saída do comando:

```bash
$ kubectl rollout status deployment nginx-deployment-rollingupdate
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 3 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 3 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 3 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 3 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 4 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 4 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 7 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 9 out of 10 new replicas have been updated...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 8 of 10 updated replicas are available...
Waiting for deployment "nginx-deployment-rollingupdate" rollout to finish: 9 of 10 updated replicas are available...
deployment "nginx-deployment-rollingupdate" successfully rolled out
```

### Estratégia Recreate

A estratégia Recreate é uma estratégia de atualização que irá remover todos os Pods do Deployment e criar novos Pods com a nova versão da imagem. A parte boa é que o deploy acontecerá rapidamente, porém o ponto negativo é que o serviço ficará indisponível durante o processo de atualização.

Vamos utilizar o manifesto `nginx-deployment-recreate.yaml` para esses testes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deployment-recreate
  name: nginx-deployment-recreate
spec:
  replicas: 10
  selector:
    matchLabels:
      app: nginx-deployment-recreate
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nginx-deployment-recreate
    spec:
      containers:
      - image: nginx:1.16.0
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: 256Mi
          requests:
            cpu: "0.25"
            memory: 128Mi
```


Perceba que agora somente temos a configuração `type: Recreate`. O Recreate não possui configurações de atualização, ou seja, não é possível definir o número máximo de Pods indisponíveis durante a atualização, afinal o Recreate irá remover todos os Pods do Deployment e criar novos Pods.

Veja o resultado quando aplicamos a atualização de um Deployment com estratégia Recreate. É possível observar que de forma bem rápida ele terminou os Pods antigos e recriou os Pods na nova versão. É possível perceber pelo nome do novo ReplicaSet.

```bash
mauroxavier@MADMAXSJR-PC:/mnt/e/repos/mauroxavierjr/descomplicando-kubernetes/03-deployment-e-estrategias-de-rollout$ kubectl get pods
NAME                                         READY   STATUS    RESTARTS   AGE
nginx-deployment-recreate-6d57b5b48b-2k7gv   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-4q5hc   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-4s2ss   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-9svxm   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-g494x   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-gnm2r   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-h69zt   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-htg7t   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-qvzlw   1/1     Running   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-tmrtb   1/1     Running   0          <invalid>
mauroxavier@MADMAXSJR-PC:/mnt/e/repos/mauroxavierjr/descomplicando-kubernetes/03-deployment-e-estrategias-de-rollout$ kubectl apply -f nginx-deployment-recreate.yaml 
deployment.apps/nginx-deployment-recreate configured
mauroxavier@MADMAXSJR-PC:/mnt/e/repos/mauroxavierjr/descomplicando-kubernetes/03-deployment-e-estrategias-de-rollout$ kubectl get pods
NAME                                         READY   STATUS      RESTARTS   AGE
nginx-deployment-recreate-6d57b5b48b-g494x   0/1     Completed   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-gnm2r   0/1     Completed   0          <invalid>
nginx-deployment-recreate-6d57b5b48b-h69zt   0/1     Completed   0          <invalid>
mauroxavier@MADMAXSJR-PC:/mnt/e/repos/mauroxavierjr/descomplicando-kubernetes/03-deployment-e-estrategias-de-rollout$ kubectl get pods
NAME                                         READY   STATUS    RESTARTS   AGE
nginx-deployment-recreate-5977f6b798-5mxmt   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-7lckn   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-89tp5   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-9dnrz   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-cfflx   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-fsdtz   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-hqmh7   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-ppp9j   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-qwz7f   1/1     Running   0          5s
nginx-deployment-recreate-5977f6b798-w29b9   1/1     Running   0          5s
```
## Fazendo Rolback de um Deployment

Realizando rollback para uma versão anterior de um Deployment.

```bash
$ kubectl rollout undo deployment nginx-deployment-recreate
deployment.apps/nginx-deployment-recreate rolled back
```

Verificando o histórico de atualizações de um Deployment.

```bash
$ kubectl rollout history deployment nginx-deployment-recreate
deployment.apps/nginx-deployment-recreate 
REVISION  CHANGE-CAUSE
2         <none>
4         <none>
5         <none>
```

Verificando as atualizações feitas nas revisões do histórico do Deployment.

```bash
$ kubectl rollout history deployment nginx-deployment-recreate --revision=4
deployment.apps/nginx-deployment-recreate with revision #4
Pod Template:
  Labels:       app=nginx-deployment-recreate
        pod-template-hash=6d57b5b48b
  Containers:
   nginx:
    Image:      nginx:1.19.0
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:      500m
      memory:   256Mi
    Requests:
      cpu:      250m
      memory:   128Mi
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
  Node-Selectors:       <none>
  Tolerations:  <none>

$ kubectl rollout history deployment nginx-deployment-recreate --revision=5
deployment.apps/nginx-deployment-recreate with revision #5
Pod Template:
  Labels:       app=nginx-deployment-recreate
        pod-template-hash=84fb86f795
  Containers:
   nginx:
    Image:      nginx:1.19.1
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:      500m
      memory:   256Mi
    Requests:
      cpu:      250m
      memory:   128Mi
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
  Node-Selectors:       <none>
  Tolerations:  <none>
```

Fazendo rollback para uma versão específica.
```bash
$ kubectl rollout undo deployment nginx-deployment-recreate --to-revision=4
deployment.apps/nginx-deployment-recreate rolled back
```

Pausar o Deployment e não permitir que ele faça nenhuma atualização.
```bash
$ kubectl rollout pause deployment nginx-deployment-recreate
deployment.apps/nginx-deployment-recreate paused
```

Despausar um Deployment.
```bash
kubectl rollout resume deployment nginx-deployment-recreate
deployment.apps/nginx-deployment-recreate resumed
```