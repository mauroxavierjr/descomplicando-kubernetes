## ReplicaSets

Quando criamos um Deployment no Kubernetes, também é criado um ReplicaSet associado a esse deployment e o ReplicaSet cria os Pods na quantidade definida no manifesto.
O ReplicaSet é responsável por observar os Pods e garantir que o número definido de réplicas está em execução.

É possível criar ReplicaSets sem Deployment, porém isso não é recomendado. O ReplicaSet não possui a capacidade de gerenciar a versão dos Pods.

Quando, por exemplo, alteramos a imagem do Container do Pod para uma nova versão o Deployment cria um novo ReplicaSet no lugar do atual já com as atualizações. O ReplicaSet anterior não é completamente esquecido pelo Deployment, ele fica salvo em histórico é é possível realizar um Rollback para a versão anterior caso necessário.

Vamos utilizar o manifesto de Deployment nginx-teste-replica-deployment.yaml para os testes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: deploy-teste
  name: nginx-teste-replica-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: deploy-teste
  strategy: {}
  template:
    metadata:
      labels:
        app: deploy-teste
    spec:
      containers:
      - image: nginx
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: "256Mi"
          requests:
            cpu: "0.25"
            memory: "128Mi"
```

Realizando o deploy do manifesto

```bash
$ kubectl apply -f nginx-teste-replica-deployment.yaml
```

Verificando os Pods.

```bash
$ kubectl get po
NAME                                              READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-8d78z   1/1     Running   0          3m26s
nginx-teste-replica-deployment-6459b55b5d-k5xwc   1/1     Running   0          3m26s
nginx-teste-replica-deployment-6459b55b5d-wwtgs   1/1     Running   0          3m26s
```

Aqui podemos verificar como funciona a nomeclatura das réplicas.

Exemplo: nginx-teste-replica-deployment-6459b55b5d-8d78z
nginx-teste-replica-deployment: Nome do deployment
6459b55b5d: ID do ReplicaSet
8d78z: ID do Pod

Aqui vamos visualizar o ReplicaSet criado após a criação do Deployment.
É possível verificar que a três réplicas solicitadas estão em execução.

```bash
$ kubectl get rs
NAME                                        DESIRED   CURRENT   READY   AGE
nginx-teste-replica-deployment-6459b55b5d   3         3         3       5m44s
```

Vamos de forma proposital deletar o Pod nginx-teste-replica-deployment-6459b55b5d-wwtgs e ver o nosso ReplicaSet atuando na criação de um novo Pod.

```bash
$ kubectl delete po nginx-teste-replica-deployment-6459b55b5d-wwtgs
pod "nginx-teste-replica-deployment-6459b55b5d-wwtgs" deleted
```

Como se trata de um cenário de teste, o ReplicaSet rapidamente criou um Pod novo para manter a quantidade de réplicas desejadas.

```bash
$ kubectl get po
NAME                                              READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-8d78z   1/1     Running   0          9m18s
nginx-teste-replica-deployment-6459b55b5d-k5xwc   1/1     Running   0          9m18s
nginx-teste-replica-deployment-6459b55b5d-lr76w   1/1     Running   0          <invalid>
```

Mas é possível ver a ação do ReplicaSet com o comando describe rs.

```bash
$ kubectl describe rs nginx-teste-replica-deployment-6459b55b5d
Name:           nginx-teste-replica-deployment-6459b55b5d
Namespace:      default
Selector:       app=deploy-teste,pod-template-hash=6459b55b5d
Labels:         app=deploy-teste
                pod-template-hash=6459b55b5d
Annotations:    deployment.kubernetes.io/desired-replicas: 3
                deployment.kubernetes.io/max-replicas: 4
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/nginx-teste-replica-deployment
Replicas:       3 current / 3 desired
Pods Status:    3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=deploy-teste
           pod-template-hash=6459b55b5d
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
Events:
  Type    Reason            Age        From                   Message
  ----    ------            ----       ----                   -------
  Normal  SuccessfulCreate  9m51s      replicaset-controller  Created pod: nginx-teste-replica-deployment-6459b55b5d-wwtgs
  Normal  SuccessfulCreate  9m51s      replicaset-controller  Created pod: nginx-teste-replica-deployment-6459b55b5d-k5xwc
  Normal  SuccessfulCreate  9m51s      replicaset-controller  Created pod: nginx-teste-replica-deployment-6459b55b5d-8d78z
  Normal  SuccessfulCreate  <invalid>  replicaset-controller  Created pod: nginx-teste-replica-deployment-6459b55b5d-lr76w
```

Podemos ver nos eventos que o Pod ID lr76w foi criado para substituir o wwtgs.

### Escalando um ReplicaSet

Podemos escalar um ReplicaSet editando o seu manifesto ou através da CLI.
No manifesto é essa alteração é feita editando o parametro spec.replicas.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deployment
  name: nginx-deployment
spec:
  replicas: 3
```

Se alterarmos de 3 para 6 e aplicar o Deployment o ReplicaSet vai entrar em ação e adicionar as réplicas a mais desejadas.

```bash
$ kubectl get po
NAME                                              READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-22qcl   1/1     Running   0          16s
nginx-teste-replica-deployment-6459b55b5d-8d78z   1/1     Running   0          19m
nginx-teste-replica-deployment-6459b55b5d-986mj   1/1     Running   0          16s
nginx-teste-replica-deployment-6459b55b5d-f8qbn   1/1     Running   0          16s
nginx-teste-replica-deployment-6459b55b5d-k5xwc   1/1     Running   0          19m
nginx-teste-replica-deployment-6459b55b5d-lr76w   1/1     Running   0          5m18s
```

Agora Vamos utilizar a linha de comando para escalar novamente de 6 Pods para 3.

```bash
$ kubectl scale deployment nginx-teste-replica-deployment --replicas=3
deployment.apps/nginx-teste-replica-deployment scaled
$ kubectl get rs
NAME                                        DESIRED   CURRENT   READY   AGE
nginx-teste-replica-deployment-6459b55b5d   3         3         3       26m
```

### Criando Novo ReplicaSet e Rollback - Com Deployment

A edição da quantidade de réplicas não é suficiente para que o Kubernetes gere uma nova versão e crie um novo ReplicaSet, para visualizar essa ação vamos alterar a imagem do Nginx e analisar o comportamento.

```yaml
    spec:
      containers:
      - image: nginx:1.19.0
        name: nginx
        resources:
          limits:
```

Após aplicar essa alteração no manifesto podemos ver que o Deployment criou o novo ReplicaSet 8976465b7 no lugar do 6459b55b5d.

```bash
$ kubectl apply -f nginx-teste-replica-deployment.yaml 
deployment.apps/nginx-teste-replica-deployment configured
$ kubectl get rs
NAME                                        DESIRED   CURRENT   READY   AGE
nginx-teste-replica-deployment-6459b55b5d   0         0         0       38m
nginx-teste-replica-deployment-8976465b7    6         6         6       26s
$ kubectl get po
NAME                                             READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-8976465b7-28vdf   1/1     Running   0          16s
nginx-teste-replica-deployment-8976465b7-4g2h4   1/1     Running   0          33s
nginx-teste-replica-deployment-8976465b7-8n868   1/1     Running   0          33s
nginx-teste-replica-deployment-8976465b7-dm792   1/1     Running   0          33s
nginx-teste-replica-deployment-8976465b7-ds98r   1/1     Running   0          18s
nginx-teste-replica-deployment-8976465b7-t6n8f   1/1     Running   0          19s
```

Podemos ver que o ReplicaSet anterior ainda é exibido com o comando get rs. Isso acontece devido o Deployment controlar um histórico de versões onde é possível realizar um rollback sempre que necessário. Com os comando abaixo é possível visualizar o controle de versão do Deployment.

```bash
$ kubectl rollout history deploy nginx-teste-replica-deployment
deployment.apps/nginx-teste-replica-deployment 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

$ kubectl describe deployment  nginx-teste-replica-deployment | grep deployment.kubernetes.io/revision
Annotations:            deployment.kubernetes.io/revision: 2

$ kubectl rollout history deploy nginx-teste-replica-deployment --revision=2
deployment.apps/nginx-teste-replica-deployment with revision #2
Pod Template:
  Labels:       app=deploy-teste
        pod-template-hash=8976465b7
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
```

Nosso Deployment está na versão 1, se precisarmos voltar para a versão anterior podemos utilizar o comando abaixo.

```bash
$ kubectl rollout undo deployment nginx-teste-replica-deployment 
deployment.apps/nginx-teste-replica-deployment rolled back

$ kubectl rollout history deploy nginx-teste-replica-deployment
deployment.apps/nginx-teste-replica-deployment 
REVISION  CHANGE-CAUSE
2         <none>
3         <none>

$ kubectl describe deployment  nginx-teste-replica-deployment | grep deployment.kubernetes.io/revision
Annotations:            deployment.kubernetes.io/revision: 3

$ kubectl rollout history deploy nginx-teste-replica-deployment --revision=3
deployment.apps/nginx-teste-replica-deployment with revision #3
Pod Template:
  Labels:       app=deploy-teste
        pod-template-hash=6459b55b5d
  Containers:
   nginx:
    Image:      nginx
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

Aqui podemos ver que após o comando undo a imagem deixou de ser nginx:1.19.0 e passou para nginx latest.

### Criando Novo ReplicaSet e Rollback - Sem Deployment

Como foi informado anteriormente, o ReplicaSet criado sem um Deployment não tem a capacidade de controlar a versão da aplicação. Isso impossibilitaria realizar as ações feitas anteriomente onde mudamos a imagem do Nginx, atualizamos os Pods e depois realizamos um rollback.

Para realizar esses testes vamos utilizar o manifesto abaixo.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  labels:
    app: replica-teste
  name: nginx-teste-replica-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: replica-teste
  template:
    metadata:
      labels:
        app: replica-teste
    spec:
      containers:
      - image: nginx:1.19.0
        name: nginx
        resources:
          limits:
            cpu: "0.5"
            memory: "256Mi"
          requests:
            cpu: "0.25"
            memory: "128Mi"
```

Após aplicar manifesto podemos ver que o novo ReplicaSet fopi criado.

```bash
$ kubectl apply -f nginx-teste-replica-replicaset.yaml 
replicaset.apps/nginx-teste-replica-replicaset created

$ kubectl get rs
NAME                                        DESIRED   CURRENT   READY   AGE
nginx-teste-replica-deployment-6459b55b5d   6         6         6       96m
nginx-teste-replica-deployment-8976465b7    0         0         0       58m
nginx-teste-replica-replicaset              3         3         3       20s

$ kubectl get po
NAME                                              READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-gmfz9   1/1     Running   0          22m
nginx-teste-replica-deployment-6459b55b5d-jnbtr   1/1     Running   0          22m
nginx-teste-replica-deployment-6459b55b5d-lqpgj   1/1     Running   0          22m
nginx-teste-replica-deployment-6459b55b5d-nlcbp   1/1     Running   0          22m
nginx-teste-replica-deployment-6459b55b5d-qdp7z   1/1     Running   0          22m
nginx-teste-replica-deployment-6459b55b5d-r79vk   1/1     Running   0          22m
nginx-teste-replica-replicaset-9246c              1/1     Running   0          2m9s
nginx-teste-replica-replicaset-gq4kh              1/1     Running   0          2m9s
nginx-teste-replica-replicaset-nfzhp              1/1     Running   0          2m9s
```

Vamos agora alterar a versão do Nginx para 1.19.3 e verificar qual será o comportamento.

```yaml
    spec:
      containers:
      - image: nginx:1.19.3
        name: nginx
```

POdemos ver abaixo que mesmo após a troca da imagem nomanifesto do ReplicaSet os POds ainda estão utilizando a imagem antiga. Isso acontece por que o ReplicaSet não faz o gerenciamento do versionamento dos Pods, ele apenas garante que a quantidade de réplicas desejadas estejam em execução. 

Somente vamos conseguir forçar que esses Pods utilizem a versão que definimos no arquivo com uma remoção forçada deles. Assim o ReplicaSet vai recriar os Pods utilizando as configurações mais recentes definidas no manifesto.

```bash
$ kubectl delete po nginx-teste-replica-replicaset-9246c
pod "nginx-teste-replica-replicaset-9246c" deleted

$ kubectl get po
NAME                                              READY   STATUS              RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-gmfz9   1/1     Running             0          30m
nginx-teste-replica-deployment-6459b55b5d-jnbtr   1/1     Running             0          30m
nginx-teste-replica-deployment-6459b55b5d-lqpgj   1/1     Running             0          30m
nginx-teste-replica-deployment-6459b55b5d-nlcbp   1/1     Running             0          30m
nginx-teste-replica-deployment-6459b55b5d-qdp7z   1/1     Running             0          30m
nginx-teste-replica-deployment-6459b55b5d-r79vk   1/1     Running             0          30m
nginx-teste-replica-replicaset-8znnk              0/1     ContainerCreating   0          6s
nginx-teste-replica-replicaset-gq4kh              1/1     Running             0          9m28s
nginx-teste-replica-replicaset-nfzhp              1/1     Running             0          9m28s

$ kubectl get po
NAME                                              READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-gmfz9   1/1     Running   0          35m
nginx-teste-replica-deployment-6459b55b5d-jnbtr   1/1     Running   0          35m
nginx-teste-replica-deployment-6459b55b5d-lqpgj   1/1     Running   0          35m
nginx-teste-replica-deployment-6459b55b5d-nlcbp   1/1     Running   0          35m
nginx-teste-replica-deployment-6459b55b5d-qdp7z   1/1     Running   0          35m
nginx-teste-replica-deployment-6459b55b5d-r79vk   1/1     Running   0          35m
nginx-teste-replica-replicaset-8znnk              1/1     Running   0          5m13s
nginx-teste-replica-replicaset-gq4kh              1/1     Running   0          14m
nginx-teste-replica-replicaset-nfzhp              1/1     Running   0          14m

$ kubectl describe po nginx-teste-replica-replicaset-8znnk | grep -i image
    Image:          nginx:1.19.3
    Image ID:       docker.io/library/nginx@sha256:ed7f815851b5299f616220a63edac69a4cc200e7f536a56e421988da82e44ed8
  Normal  Pulling    38s   kubelet            Pulling image "nginx:1.19.3"
```





























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

### Apagando um ReplicaSet

O comando abaixo pode ser utilizado para apagar um ReplicaSet, essa ação também remove os Pods relacionados a ele.

```bash
$ kubectl get rs
NAME                                        DESIRED   CURRENT   READY   AGE
nginx-teste-replica-deployment-6459b55b5d   6         6         6       109m
nginx-teste-replica-deployment-8976465b7    0         0         0       71m
nginx-teste-replica-replicaset              3         3         3       13m

$ kubectl delete rs nginx-teste-replica-replicaset
replicaset.apps "nginx-teste-replica-replicaset" deleted

$ kubectl get rs
NAME                                        DESIRED   CURRENT   READY   AGE
nginx-teste-replica-deployment-6459b55b5d   6         6         6       109m
nginx-teste-replica-deployment-8976465b7    0         0         0       71m

$ kubectl get po
NAME                                              READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-gmfz9   1/1     Running   0          34m
nginx-teste-replica-deployment-6459b55b5d-jnbtr   1/1     Running   0          34m
nginx-teste-replica-deployment-6459b55b5d-lqpgj   1/1     Running   0          34m
nginx-teste-replica-deployment-6459b55b5d-nlcbp   1/1     Running   0          34m
nginx-teste-replica-deployment-6459b55b5d-qdp7z   1/1     Running   0          34m
nginx-teste-replica-deployment-6459b55b5d-r79vk   1/1     Running   0          34m
```

Mas e se apagarmos um ReplicaSet que foi criado por um Deployment? Nesse caso o Deployment vai criar novamente o ReplicaSet removido e o ReplicaSet vai subir novos Pods.

```bash
$ kubectl delete rs nginx-teste-replica-deployment-6459b55b5d
replicaset.apps "nginx-teste-replica-deployment-6459b55b5d" deleted

$ kubectl get rs
NAME                                        DESIRED   CURRENT   READY   AGE
nginx-teste-replica-deployment-6459b55b5d   6         6         6       12s
nginx-teste-replica-deployment-8976465b7    0         0         0       74m

$ kubectl get po
NAME                                              READY   STATUS    RESTARTS   AGE
nginx-teste-replica-deployment-6459b55b5d-98lq7   1/1     Running   0          17s
nginx-teste-replica-deployment-6459b55b5d-lg6rq   1/1     Running   0          17s
nginx-teste-replica-deployment-6459b55b5d-qj5v5   1/1     Running   0          17s
nginx-teste-replica-deployment-6459b55b5d-rckhv   1/1     Running   0          17s
nginx-teste-replica-deployment-6459b55b5d-tcsjz   1/1     Running   0          17s
nginx-teste-replica-deployment-6459b55b5d-v5rvv   1/1     Running   0          17s
```

Nos eventos do Deployment podemos ver a ação que foi iniciada.

```bash
$ kubectl describe deploy nginx-teste-replica-deployment | tail -n 1
  Normal  ScalingReplicaSet  7m31s              deployment-controller  Scaled up replica set nginx-teste-replica-deployment-6459b55b5d from 0 to 6
```