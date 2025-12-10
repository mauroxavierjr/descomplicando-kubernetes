## DaemonSets

DeamonSet é um objeto que garante que todos os nós do cluster executem uma réplica do um Pod. Ele é muito utilizado para aplicações de monitoramento e logs que precisam coletar informações e métricas em cada nó do cluster.

Esses são alguns dos casos de uso:
*  Execução de agentes de monitoramento, como o Prometheus Node Exporter ou o Fluentd.
*  Execução de um proxy de rede em todos os nós do cluster, como kube-proxy, Weave Net, Calico ou Flannel.
*  Execução de agentes de segurança em cada nó do cluster, como Falco ou Sysdig.

O DaemonSet tem a capacidade de identificar se um nó foi adicionado ao cluster e garantir que nesse novo nó um Pod também vai estar em execução.

## Criando um DaemonSet

Vamos trabalhar nos testes utilizando o arquivo manifesto node-exporter-daemonset.yaml. Abaixo estão a explicação de cada linha do nosso yaml.

```yaml
apiVersion: apps/v1 # Versão da API do Kubernetes do objeto
kind: DaemonSet # Tipo do objeto
metadata: # Informações sobre o objeto
  name: node-exporter # Nome do objeto
spec: # Especificação do objeto
  selector: # Seletor do objeto
    matchLabels: # Labels que serão utilizadas para selecionar os Pods
      app: node-exporter # Label que será utilizada para selecionar os Pods
  template: # Template do objeto
    metadata: # Informações sobre o objeto
      labels: # Labels que serão adicionadas aos Pods
        app: node-exporter # Label que será adicionada aos Pods
    spec: # Especificação do objeto, no caso, a especificação do Pod
      hostNetwork: true # Habilita o uso da rede do host, usar com cuidado
      containers: # Lista de contêineres que serão executados no Pod
      - name: node-exporter # Nome do contêiner
        image: prom/node-exporter:latest # Imagem do contêiner
        ports: # Lista de portas que serão expostas no contêiner
        - containerPort: 9100 # Porta que será exposta no contêiner
          hostPort: 9100 # Porta que será exposta no host
        volumeMounts: # Lista de volumes que serão montados no contêiner, pois o node-exporter precisa de acesso ao /proc e /sys
        - name: proc # Nome do volume
          mountPath: /host/proc # Caminho onde o volume será montado no contêiner
          readOnly: true # Habilita o modo de leitura apenas
        - name: sys # Nome do volume 
          mountPath: /host/sys # Caminho onde o volume será montado no contêiner
          readOnly: true # Habilita o modo de leitura apenas
      volumes: # Lista de volumes que serão utilizados no Pod
      - name: proc # Nome do volume
        hostPath: # Tipo de volume 
          path: /proc # Caminho do volume no host
      - name: sys # Nome do volume
        hostPath: # Tipo de volume
          path: /sys # Caminho do volume no host
```

Aplicando o manifesto podemos visualizar a criação do DaemonSet e dos Pods.

```bash
$ kubectl apply -f node-exporter-daemonset.yaml 
daemonset.apps/node-exporter created

$ kubectl get po
NAME                  READY   STATUS    RESTARTS   AGE
node-exporter-d6qxq   1/1     Running   0          36s
node-exporter-s6gv2   1/1     Running   0          36s
node-exporter-x7f5k   1/1     Running   0          36s

$ kubectl get ds
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-exporter   3         3         3       3            3           <none>          58s

$ kubectl describe ds node-exporter
Name:           node-exporter
Selector:       app=node-exporter
Node-Selector:  <none>
Labels:         app=node-exporter
Annotations:    deprecated.daemonset.template.generation: 1
Desired Number of Nodes Scheduled: 3
Current Number of Nodes Scheduled: 3
Number of Nodes Scheduled with Up-to-date Pods: 3
Number of Nodes Scheduled with Available Pods: 3
Number of Nodes Misscheduled: 0
Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=node-exporter
  Containers:
   node-exporter:
    Image:        prom/node-exporter:latest
    Port:         9100/TCP
    Host Port:    9100/TCP
    Environment:  <none>
    Mounts:
      /host/proc from proc (ro)
      /host/sys from sys (ro)
  Volumes:
   proc:
    Type:          HostPath (bare host directory volume)
    Path:          /proc
    HostPathType:
   sys:
    Type:          HostPath (bare host directory volume)
    Path:          /sys
    HostPathType:
  Node-Selectors:  <none>
  Tolerations:     <none>
Events:
  Type    Reason            Age   From                  Message
  ----    ------            ----  ----                  -------
  Normal  SuccessfulCreate  93s   daemonset-controller  Created pod: node-exporter-x7f5k
  Normal  SuccessfulCreate  93s   daemonset-controller  Created pod: node-exporter-d6qxq
  Normal  SuccessfulCreate  93s   daemonset-controller  Created pod: node-exporter-s6gv2
```

Se utilizarmos o parâmetro -owide na visualizaçõa dos pods podemos ver que cada um foi criado em um node.

```bash
$ kubectl get po -owide
NAME                  READY   STATUS    RESTARTS   AGE     IP           NODE           NOMINATED NODE   READINESS GATES
node-exporter-d6qxq   1/1     Running   0          2m35s   172.19.0.2   kind-worker2   <none>           <none>
node-exporter-s6gv2   1/1     Running   0          2m35s   172.19.0.4   kind-worker    <none>           <none>
node-exporter-x7f5k   1/1     Running   0          2m35s   172.19.0.5   kind-worker3   <none>           <none>
```

## Removendo um DaemonSet

O comando abaixo remove o DaemonSet e todos os seus Pods.

```bash
$ kubectl delete ds node-exporter
```