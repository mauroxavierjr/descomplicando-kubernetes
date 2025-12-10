## O que são probes?

Probes são uma forma de monitorar o Pod para saber se ele está saudável ou não. Existem três tipos de probes no Kubernetes:

A imagem abaixo resume de forma simples e clara a diferença entre cada uma das probes.

![Diferenças entre as probes do Kubernetes](./images/probes.png)

### Testes com Probes

Vamos utilizar o arquivo manifesto nginx-probes.yaml para nossos testes.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: probes-test
  name: nginx-probes
spec:
  replicas: 3
  selector:
    matchLabels:
      app: probes-test
  strategy: {}
  template:
    metadata:
      labels:
        app: probes-test
    spec: 
      containers:
      - image: nginx:latest
        name: nginx
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
          requests:
            memory: "64Mi"
            cpu: "250m"
       livenessProbe: # Onde definimos a nossa probe de vida
          exec: # O tipo exec é utilizado quando queremos executar algo dentro do container.
            command: # Onde iremos definir qual comando iremos executar
              - curl
              - -f
              - http://localhost:80/
          initialDelaySeconds: 10 # O tempo que iremos esperar para executar a primeira vez a probe
          periodSeconds: 10 # De quanto em quanto tempo iremos executar a probe
          timeoutSeconds: 5 # O tempo que iremos esperar para considerar que a probe falhou
          successThreshold: 1 # O número de vezes que a probe precisa passar para considerar que o container está pronto
          failureThreshold: 3 # O número de vezes que a probe precisa falhar para considerar que o container não está pronto
        readinessProbe: # Onde definimos a nossa probe de prontidão
          httpGet: # O tipo de teste que iremos executar, neste caso, iremos executar um teste HTTP
            path: / # O caminho que iremos testar
            port: 80 # A porta que iremos testar
          initialDelaySeconds: 10 # O tempo que iremos esperar para executar a primeira vez a probe
          periodSeconds: 10 # De quanto em quanto tempo iremos executar a probe
          timeoutSeconds: 5 # O tempo que iremos esperar para considerar que a probe falhou
          successThreshold: 1 # O número de vezes que a probe precisa passar para considerar que o container está pronto
          failureThreshold: 3 # O número de vezes que a probe precisa falhar para considerar que o container não está pronto
        startupProbe: # Onde definimos a nossa probe de inicialização
          tcpSocket: # O tipo de teste que iremos executar, neste caso, iremos executar um teste TCP
            port: 80 # A porta que iremos testar
          initialDelaySeconds: 10 # O tempo que iremos esperar para executar a primeira vez a probe
          periodSeconds: 10 # De quanto em quanto tempo iremos executar a probe
          timeoutSeconds: 5 # O tempo que iremos esperar para considerar que a probe falhou
          successThreshold: 1 # O número de vezes que a probe precisa passar para considerar que o container está pronto
          failureThreshold: 3 # O número de vezes que a probe precisa falhar para considerar que o container não está pronto
```
Ao aplicar manifesto podemos visualizar as configurações das probes com um describe do Deployment.

```bash
$ kubectl describe deploy nginx-probes
Name:                   nginx-probes
Namespace:              default
CreationTimestamp:      Wed, 10 Dec 2025 19:14:15 -0300
Labels:                 app=probes-test
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=probes-test
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=probes-test
  Containers:
   nginx:
    Image:      nginx:latest
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     500m
      memory:  128Mi
    Requests:
      cpu:         250m
      memory:      64Mi
    Liveness:      exec [curl -f http://localhost:80] delay=10s timeout=5s period=10s #success=1 #failure=3
    Readiness:     http-get http://:80/ delay=10s timeout=5s period=10s #success=1 #failure=3
    Startup:       tcp-socket :80 delay=10s timeout=5s period=10s #success=1 #failure=3
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-probes-546468bb5b (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  43s   deployment-controller  Scaled up replica set nginx-probes-546468bb5b from 0 to 3
```

#### Simulação de Falha: Liveness Probe

Fiz uma alteração onde executamos o comando curl e troquei o endereço de "localhost" para "meuhost".

```yaml
        livenessProbe:
          exec:
            command:
              - curl
              - -f
              - http://meuhost:80/
```

Veja o resultado quando visualizamos os pods em execução.

```bash
kubectl get po
NAME                            READY   STATUS    RESTARTS      AGE
nginx-probes-546468bb5b-kssx9   1/1     Running   0             11m
nginx-probes-546468bb5b-t6tvq   1/1     Running   0             11m
nginx-probes-55d5488df4-29vdr   0/1     Running   0             115s
nginx-probes-55d5488df4-9gbnf   1/1     Running   2 (31s ago)   2m15s
```

Podemos ver que o Deployment criou o novo ReplicaSet 55d5488df4 e já tentou por duas vezes validar a integridade do Pod e nçao conseguiu. E como o comportamento do LivenessProbe é reiniciar o Pod quando encontra uma falha, ele vai seguir fazendo isso até que ele consiga realizar um teste bem sucedido (o que nunca vai acontecer aqui).

Vamos executar um describe no Pod para visualizar mais detalhes.

```bash
$ kubectl describe po nginx-probes-55d5488df4-9gbnf | tail -n 20
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  6m52s                  default-scheduler  Successfully assigned default/nginx-probes-55d5488df4-9gbnf to kind-worker3
  Normal   Pulled     6m50s                  kubelet            Successfully pulled image "nginx:latest" in 1.172s (1.172s including waiting). Image size: 59795293 bytes.
  Warning  Unhealthy  5m57s (x2 over 6m17s)  kubelet            Liveness probe failed: command timed out: "curl -f http://meuhost:80" timed out after 5s
  Normal   Pulled     5m55s                  kubelet            Successfully pulled image "nginx:latest" in 1.14s (1.14s including waiting). Image size: 59795293 bytes.
  Normal   Pulled     5m7s                   kubelet            Successfully pulled image "nginx:latest" in 1.081s (1.081s including waiting). Image size: 59795293 bytes.
  Normal   Pulled     4m17s                  kubelet            Successfully pulled image "nginx:latest" in 1.112s (1.112s including waiting). Image size: 59795293 bytes.
  Normal   Pulling    3m28s (x5 over 6m52s)  kubelet            Pulling image "nginx:latest"
  Normal   Created    3m27s (x5 over 6m50s)  kubelet            Created container: nginx
  Normal   Started    3m27s (x5 over 6m50s)  kubelet            Started container nginx
  Normal   Pulled     3m27s                  kubelet            Successfully pulled image "nginx:latest" in 1.139s (1.139s including waiting). Image size: 59795293 bytes.
  Normal   Killing    108s (x6 over 5m57s)   kubelet            Container nginx failed liveness probe, will be restarted
  Warning  Unhealthy  108s (x16 over 6m8s)   kubelet            Liveness probe failed:   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
\r  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0\r  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0\r  0     0    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0\r  0     0    0     0    0     0      0      0 --:--:--  0:00:02 --:--:--     0\r  0     0    0     0    0     0      0      0 --:--:--  0:00:03 --:--:--     0curl: (6) Could not resolve host: meuhost
  Warning  BackOff  48s (x7 over 108s)  kubelet  Back-off restarting failed container nginx in pod nginx-probes-55d5488df4-9gbnf_default(24e4aea6-d93a-47cb-98eb-6a6bcedc810d)
```

Aqui tudo fica mais claro, podemos ver a falha do Livenes Probe com a mensagem de que o host "meuhost" não existe.

#### Simulação de Falha: Readiness Probe

Fiz uma alteração no caminho que o Readiness Probe deve utilizar para validar o acesso ao website e permitir as conexões ao Pod.

```yaml
        readinessProbe:
          httpGet:
            path: /meusite
            port: 80
```
Com essa alteração o Pod nunca vai iniciar e ficar pronto para receber as conexões.
Veja que ele fica em Running mais o Ready fica em 0/1.

```bash
$ kubectl get po
NAME                            READY   STATUS    RESTARTS   AGE
nginx-probes-546468bb5b-4wq5d   1/1     Running   0          21m
nginx-probes-546468bb5b-kssx9   1/1     Running   0          42m
nginx-probes-546468bb5b-t6tvq   1/1     Running   0          42m
nginx-probes-685fb8596-rvr9c    0/1     Running   0          18m
```

Verificando os detalhes no describe pode vemos o erro 404.

```bash
$ kubectl describe po nginx-probes-685fb8596-rvr9c | tail -n 9
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  19m                  default-scheduler  Successfully assigned default/nginx-probes-685fb8596-rvr9c to kind-worker3
  Normal   Pulling    19m                  kubelet            Pulling image "nginx:latest"
  Normal   Pulled     19m                  kubelet            Successfully pulled image "nginx:latest" in 1.265s (1.265s including waiting). Image size: 59795293 bytes.
  Normal   Created    19m                  kubelet            Created container: nginx
  Normal   Started    19m                  kubelet            Started container nginx
  Warning  Unhealthy  4m9s (x96 over 14m)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
```

#### Simulação de Falha: Startup Probe

Fiz uma alteração da porta de o Startup Probe deve utilizar para identificar que o Pod iniciou corretamente.
Essa alteração vai fazer com que o Kubernetes entenda que o Pod não iniciou corretamente e não vai seguir para a validação das demais probes.

```yaml
        startupProbe:
          tcpSocket:
            port: 99
```

Veja abaixo o comportamento do Pod nessa situação. Como a porta 99 não existe no Container, o Startup Probbe nunca vai permitir a inicialização do do Pod e vai ficar realizando restarts até que seja resolvido.

```bash
$ kubectl get po
NAME                            READY   STATUS    RESTARTS      AGE
nginx-probes-546468bb5b-4wq5d   1/1     Running   0             33m
nginx-probes-546468bb5b-kssx9   1/1     Running   0             53m
nginx-probes-546468bb5b-t6tvq   1/1     Running   0             53m
nginx-probes-f966f7f78-jwfzn    0/1     Running   1 (11s ago)   51s
```

Com o describe pod podemos ver detalhes sobre o erro.

```bash
$ kubectl describe pod nginx-probes-f966f7f78-jwfzn | tail -n 14
Events:
  Type     Reason     Age                         From               Message
  ----     ------     ----                        ----               -------
  Normal   Scheduled  3m59s                       default-scheduler  Successfully assigned default/nginx-probes-f966f7f78-jwfzn to kind-worker
  Normal   Pulled     3m57s                       kubelet            Successfully pulled image "nginx:latest" in 1.476s (1.476s including waiting). Image size: 59795293 bytes.
  Normal   Pulled     3m17s                       kubelet            Successfully pulled image "nginx:latest" in 1.45s (1.45s including waiting). Image size: 59795293 bytes.
  Normal   Pulled     2m37s                       kubelet            Successfully pulled image "nginx:latest" in 1.425s (1.425s including waiting). Image size: 59795293 bytes.
  Normal   Pulled     118s                        kubelet            Successfully pulled image "nginx:latest" in 1.163s (1.163s including waiting). Image size: 59795293 bytes.
  Normal   Pulling    <invalid> (x5 over 3m59s)   kubelet            Pulling image "nginx:latest"
  Warning  Unhealthy  <invalid> (x12 over 3m39s)  kubelet            Startup probe failed: dial tcp 10.244.2.15:99: connect: connection refused
  Normal   Killing    <invalid> (x4 over 3m19s)   kubelet            Container nginx failed startup probe, will be restarted
  Normal   Created    <invalid> (x5 over 3m57s)   kubelet            Created container: nginx
  Normal   Started    <invalid> (x5 over 3m57s)   kubelet            Started container nginx
  Normal   Pulled     <invalid>                   kubelet            Successfully pulled image "nginx:latest" in 1.169s (1.169s including waiting). Image size: 59795293 bytes.
  ```

