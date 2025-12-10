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

Podemos ver abaixo que mesmo após a troca da imagem nomanifesto do ReplicaSet os POds ainda estão utilizando a imagem antiga. Isso acontece por que o ReplicaSet não faz o gerenciamento do versionamento dos Pods, ele apenas garante que a quantidade de réplicas desejadas estejam em execução. 

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