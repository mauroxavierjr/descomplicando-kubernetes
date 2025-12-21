## Volumes no Kubernetes

### EmptyDir

É um tipo de volume criado durante a criação do Pod e é destruído quando o Pod é terminado. Não é um tipo de volume muito utilizado, um caso de uso seria quando você precisa compartilhar dados entre os containers de um Pod.

Abaixo temos um exemplo de um manifesto chamado pod-emptydir.yaml.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-emptydir
spec:
  containers:
  - name: ubuntu 
    image: ubuntu
    args: # argumentos que serão passados para o container
    - sleep # usando o comando sleep para manter o container em execução
    - infinity # o argumento infinity faz o container esperar para sempre
    volumeMounts: # lista de volumes que serão montados no container
    - name: primeiro-emptydir # nome do volume
      mountPath: /shareddir # diretório onde o volume será montado 
  volumes: # lista de volumes
  - name: primeiro-emptydir # nome do volume
    emptyDir: # tipo do volume
      sizeLimit: 256Mi # tamanho máximo do volume
```

Vamos criar o pod utilizando o arquivo manifesto.

```bash
$ kubectl apply -f pod-emptydir.yaml 
pod/pod-emptydir created

$ kubectl get pod
NAME           READY   STATUS    RESTARTS   AGE
pod-emptydir   1/1     Running   0          26s
```

Agora vamos conectar dentro do conteinar para realizar a primeira parte dos nossos testes.
Conectando nele é possível verificar que o diretório /shareddir foi criado e está vazio.

```bash
$ kubectl exec -it pod-emptydir -- bash
root@pod-emptydir:/# ls /shareddir/
root@pod-emptydir:/#
```

Vamos criar um arquivo dentro do diretório e observar o que vai acontecer quando recriarmos o POd.

```bash
root@pod-emptydir:/# touch /shareddir/meuteste
root@pod-emptydir:/# ls -l /shareddir/
total 0
-rw-r--r-- 1 root root 0 Dec 20 23:17 meuteste
```

Ok, agora vamos deletar o POd e verificar se ao recria-lo utilizando o manifesto nos teremos o arquivo onde criamos.

```bash
$ kubectl get pod pod-emptydir 
NAME           READY   STATUS    RESTARTS   AGE
pod-emptydir   1/1     Running   0          6m37s
$ kubectl delete pod pod-emptydir
pod "pod-emptydir" deleted
$ kubectl apply -f pod-emptydir.yaml 
pod/pod-emptydir created
$ kubectl exec -it pod-emptydir -- bash
root@pod-emptydir:/# ls /shareddir/
root@pod-emptydir:/# 
```

Aqui podemos verificar o funcionamento de um volume emptyDir como um volume temporário que tem todo seu conteúdo perdido quando o Pod é recriado.

### Storage Class

Uma StorageClass no Kubernetes é um objeto que descreve e define diferentes classes de armazenamento disponíveis no cluster. Essas classes de armazenamento podem ser usadas para provisionar dinamicamente PersistentVolumes (PVs) de acordo com os requisitos dos PersistentVolumeClaims (PVCs) criados pelos usuários.

A StorageClass é útil para gerenciar e organizar diferentes tipos de armazenamento, como armazenamento em disco rápido e caro ou armazenamento em disco mais lento e barato. Além disso, a StorageClass pode ser usada para definir diferentes políticas de retenção, provisionamento e outras características de armazenamento específicas.

Os administradores do cluster podem criar e gerenciar várias StorageClasses para permitir que os usuários finais escolham a classe de armazenamento adequada para suas necessidades.

Cada StorageClass é definida com um provisionador, que é responsável por criar PersistentVolumes dinamicamente conforme necessário. Os provisionadores podem ser internos (fornecidos pelo próprio Kubernetes) ou externos (fornecidos por provedores de armazenamento específicos).

Inclusive os provisionadores podem ser diferentes para cada provedor de nuvem ou onde o Kubernetes está sendo executado. Vou listar alguns provisionadores que são usados e seus respectivos provedores:

- `kubernetes.io/aws-ebs`: AWS Elastic Block Store (EBS)
- `kubernetes.io/azure-disk`: Azure Disk
- `kubernetes.io/gce-pd`: Google Compute Engine (GCE) Persistent Disk
- `kubernetes.io/cinder`: OpenStack Cinder
- `kubernetes.io/vsphere-volume`: vSphere
- `kubernetes.io/no-provisioner`: Volumes locais
- `kubernetes.io/host-path`: Volumes locais

E se você estiver usando o Kubernetes em um ambiente local, como o Minikube, o provisionador padrão é o `kubernetes.io/host-path`, que cria volumes PersistentVolume no diretório do host. Já no Kind, o provisionador padrão é o `rancher.io/local-path`, que cria volumes PersistentVolume no diretório do host.

Para ver a lista completa de provisionadores, consulte a documentação do Kubernetes no link [https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner](https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner).

#### Testes - Storage Class

Como estamos realizando nossos teste utilizando um cluster Kind, podemos ver a Storage Class padrão dele já disponível com o comando abaixo.

```bash
$ kubectl get sc
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  8d
```

Podemos usar o comando abaixo para gerar os detalhes do Storage Class padrão.

```bash
$ kubectl describe sc standard
Name:            standard
IsDefaultClass:  Yes
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"},"name":"standard"},"provisioner":"rancher.io/local-path","reclaimPolicy":"Delete","volumeBindingMode":"WaitForFirstConsumer"}
,storageclass.kubernetes.io/is-default-class=true
Provisioner:           rancher.io/local-path
Parameters:            <none>
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>
```

POdmeos observar alguns detalhes interessantes no describe dessa Storage Class.

- IsDefaultClass:  Yes
Define o Storage Class como paddrão para ser utilizado por qualquer Claim que não tenha um Storage Class definido.

- Provisioner: rancher.io/local-path
Definição do provisioner que será utilizado, esse no caso vai disponibilizar um volume em um diretório local do host.

Vamos criar um outro Storage Class através do arquivo manifesto lab-sc.yaml.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: lab-sc
provisioner: kubernetes.io/no-provisioner
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

Agora podemos aplicar o arquivo e usar um comando describe para verificar nosso Storage Class criado.

```bash
$ kubectl apply -f lab-sc.yaml 
storageclass.storage.k8s.io/lab-sc created

$ kubectl get sc
NAME                 PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
lab-sc               kubernetes.io/no-provisioner   Retain          WaitForFirstConsumer   false                  6s
standard (default)   rancher.io/local-path          Delete          WaitForFirstConsumer   false                  8d

$ kubectl describe sc lab-sc
Name:            lab-sc
IsDefaultClass:  No
Annotations:     kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"storage.k8s.io/v1","kind":"StorageClass","metadata":{"annotations":{},"name":"lab-sc"},"provisioner":"kubernetes.io/no-provisioner","reclaimPolicy":"Retain","volumeBindingMode":"WaitForFirstConsumer"}

Provisioner:           kubernetes.io/no-provisioner
Parameters:            <none>
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Retain
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>
```

Só com o Storage Class não vamos conseguir fazer muita coisa. Vamos precisar seguir para a criação de um Persistent Volume e Persistent Claim.

### Persistent Volume

O PV é um objeto que representa um recurso de armazenamento físico em um cluster Kubernetes. Ele pode ser um disco rígido em um nó do cluster, um dispositivo de armazenamento em rede (NAS) ou mesmo um serviço de armazenamento em nuvem, como o AWS EBS ou Google Cloud Persistent Disk. 

O PV é utilizado para fornecer armazenamento durável, ou seja, os dados armazenados no PV permanecem disponíveis mesmo quando o container é reiniciado ou movido para outro nó.

No Kubernetes, você pode usar várias soluções de armazenamento como Persistent Volumes (PVs). Essas soluções podem ser divididas em dois tipos: armazenamento local e armazenamento em rede. Vou te dar exemplos de algumas opções populares de cada tipo:

**Armazenamento local:**

- HostPath: É uma maneira simples de usar um diretório do nó do cluster como armazenamento. É útil principalmente para testes e desenvolvimento, pois não é apropriado para ambientes de produção, já que os dados armazenados só estão disponíveis no nó específico.

**Armazenamento em rede:**

- NFS (Network File System): É um sistema de arquivos de rede que permite compartilhar arquivos entre várias máquinas na rede. É uma opção comum para armazenamento compartilhado em um cluster Kubernetes.

- iSCSI (Internet Small Computer System Interface): É um protocolo que permite a conexão de dispositivos de armazenamento de blocos, como SAN (Storage Area Network), por meio de redes IP. Pode ser usado como um PV no Kubernetes.

- Ceph RBD (RADOS Block Device): É uma solução de armazenamento distribuído e altamente escalável que oferece suporte ao armazenamento em bloco, objeto e arquivo. Com o RBD, você pode criar volumes de blocos virtualizados que podem ser montados como PVs no Kubernetes.

- GlusterFS: É um sistema de arquivos distribuído e escalável que permite criar volumes de armazenamento compartilhado em vários nós do cluster. Pode ser usado como um PV no Kubernetes.

- Serviços de armazenamento em nuvem: Fornecedores de nuvem como AWS, Google Cloud e Microsoft Azure oferecem soluções de armazenamento que podem ser integradas ao Kubernetes. Exemplos incluem AWS Elastic Block Store (EBS), Google Cloud Persistent Disk e Azure Disk Storage.

#### Testes - Persistent Volume

Primeiro vamos criar um Storage Class utilizando o aruqivo manifesto lab-sc-nfs.yaml abaixo.
Ele vai estar vinculado a um compartilhamento NFS na máquina local.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass 
metadata:
  name: lab-sc-nfs
provisioner: kubernetes.io/no-provisioner # Provisionador que será utilizado para criar o PV
reclaimPolicy: Retain # Política de reivindicação do PV, ou seja, o PV não será excluído quando o PVC for excluído
volumeBindingMode: WaitForFirstConsumer
parameters: # Parâmetros que serão utilizados pelo provisionador
  archiveOnDelete: "false" # Parâmetro que indica se os dados do PV devem ser arquivados quando o PV for excluído
```

Vamos agora  criar o arquivo manifesto do Parsistent Volume chamado lab-pv-nfs.yaml e entender seus parametros.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: lab-pv-nfs
  labels:
    storage: nfs # Label que será utilizada para identificar o PV
spec: # Especificações do nosso PV
  capacity: # Capacidade do PV
    storage: 1Gi # 1 Gigabyte de armazenamento
  accessModes: # Modos de acesso ao PV
    - ReadWriteOnce # Modo de acesso ReadWriteOnce, ou seja, o PV pode ser montado como leitura e escrita por um único nó
  persistentVolumeReclaimPolicy: Retain # Política de reivindicação do PV, ou seja, o PV não será excluído quando o PVC for excluído
  nfs: # Tipo de armazenamento que vamos utilizar, no caso o NFS
    server: 192.168.15.241 # Endereço do servidor NFS
    path: "/mnt/nfs" # Compartilhamento do servidor NFS
  storageClassName: lab-sc-nfs # Nome da classe de armazenamento que será utilizada
```

- `kind: PersistentVolume`: Aqui estamos definindo o tipo de objeto que estamos criando, no caso um `PersistentVolume`.

Outro ponto importante de mencionar é a seção `spec`, que é onde definimos as especificações do nosso PV.

- `spec.capacity.storage`: Aqui estamos definindo a capacidade do nosso PV, no caso 1 Gigabyte de armazenamento.
- `spec.accessModes`: Aqui estamos definindo os modos de acesso ao PV, no caso o modo `ReadWriteOnce`, que significa que o PV pode ser montado como leitura e escrita por um único nó. Aqui nós temos mais alguns modos de acesso:
  - `ReadOnlyMany`: O PV pode ser montado como somente leitura por vários nós.
  - `ReadWriteMany`: O PV pode ser montado como leitura e escrita por vários nós.
- `spec.persistentVolumeReclaimPolicy`: Aqui estamos definindo a política de reivindicação do PV, no caso a política `Retain`, que significa que o PV não será excluído quando o PVC for excluído. Aqui nós temos mais algumas políticas:
  - `Recycle`: O PV será excluído quando o PVC for excluído, mas antes disso ele será limpo, ou seja, todos os dados serão apagados.
  - `Delete`: O PV será excluído quando o PVC for excluído.

Outra seção importante é a seção `hostPath`, que é onde definimos o tipo de armazenamento que vamos utilizar, no caso um `hostPath`. Vou detalhar abaixo os tipos de armazenamento que podemos utilizar:

- `hostPath`: É uma maneira simples de usar um diretório do nó do cluster como armazenamento. É útil principalmente para testes e desenvolvimento, pois não é apropriado para ambientes de produção, já que os dados armazenados só estão disponíveis no nó específico. Ele é ideal em cenários de testes com somente um node.
- `nfs`: É um sistema de arquivos de rede que permite compartilhar arquivos entre várias máquinas na rede. É uma opção comum para armazenamento compartilhado em um cluster Kubernetes.
- `iscsi`: É um protocolo que permite a conexão de dispositivos de armazenamento de blocos, como SAN (Storage Area Network), por meio de redes IP.
- `csi`: Que significa Container Storage Interface, é um recurso que permite a integração de soluções de armazenamento de terceiros com o Kubernetes. O CSI permite que os provedores de armazenamento implementem seus próprios plugins de armazenamento e os integrem ao Kubernetes. É graças ao CSI que podemos utilizar soluções de armazenamento de terceiros, como o AWS EBS, Google Cloud Persistent Disk e Azure Disk Storage.
- `cephfs`: É um sistema de arquivos distribuído e escalável que permite criar volumes de armazenamento compartilhado em vários nós do cluster.
- `local`: É um tipo de armazenamento que permite a criação de volumes locais, onde você pode especificar o caminho do diretório onde os dados serão armazenados. É útil principalmente para testes e desenvolvimento, já que não é apropriado para ambientes de produção, já que os dados armazenados só estão disponíveis no node específico. A diferença entre o `hostPath` e o `local` é que o `local` é um recurso nativo do Kubernetes, enquanto o `hostPath` é um recurso do Kubernetes que utiliza o recurso nativo do Docker e não é recomendado quando estamos com mais de um node no cluster.
- `fc`: É um protocolo que permite a conexão de dispositivos de armazenamento de blocos utilizando redes de fibra óptica. É uma opção comum para armazenamento compartilhado em um cluster Kubernetes.

Eu listei somente os tipos de armazenamento mais comuns, mas você pode encontrar mais informações sobre os tipos de armazenamento no [Kubernetes Docs](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#types-of-persistent-volumes).

E por último, temos a seção `storageClassName`, que é onde definimos o nome da classe de armazenamento que iremos adicionar o PV

Vamos agora criar o Storage Class e o Persistent Volume utilizando os arquivos manifesto.

```bash
$ kubectl apply -f lab-sc-nfs.yaml
storageclass.storage.k8s.io/lab-sc-nfs created

$ kubectl apply -f lab-pv-nfs.yaml
persistentvolume/lab-pv-nfs created

$ kubectl get sc
NAME         PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
lab-sc-nfs   kubernetes.io/no-provisioner   Retain          WaitForFirstConsumer   false                  15s

$ kubectl get pv
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
lab-pv-nfs   1Gi        RWO            Retain           Available           lab-sc-nfs     <unset>                          11s
```

Podemos observar que o nosso Persistent Volume foi criado e está associado ao Storage Class lab-sc-nfs. O status available indica que ele está disponível para ser vinculado a um Persistent Volume Claim.


### Persistent Volume Claim

O PVC é uma solicitação de armazenamento feita pelos usuários ou aplicativos no cluster Kubernetes. Ele permite que os usuários solicitem um volume específico, com base em tamanho, tipo de armazenamento e outras características. O PVC age como uma "assinatura" que reivindica um PV para ser usado por um contêiner. O Kubernetes tenta associar automaticamente um PVC a um PV compatível, garantindo que o armazenamento seja alocado corretamente.

Através do PVC, as pessoas podem abstrair os detalhes de cada tipo de armazenamento, permitindo maior flexibilidade e portabilidade entre diferentes ambientes e provedores de infraestrutura. Ele também permite que os usuários solicitem volumes com diferentes características, como tamanho, tipo de armazenamento e modo de acesso.

Todo PVC é associado a um Storage Class ou a um Persistent Volume. O Storage Class é um objeto que descreve e define diferentes classes de armazenamento disponíveis no cluster. Já o Persistent Volume é um recurso que representa um volume de armazenamento disponível para ser usado pelo cluster.


#### Testes - Persistent Volume Claim

Vamos aplicar o manifesto lab-pvc-nfs.yaml para criar o nosso Persistent Volume Claim associado ao Storage Class criando anteriormente.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: lab-pvc-nfs
spec:
  accessModes: # modo de acesso ao volume
    - ReadWriteOnce # modo de acesso RWO, ou seja, somente leitura e escrita por um nó
  resources:
    requests: # solicitação de recursos
      storage: 1Gi # tamanho do volume que ele vai solicitar
  storageClassName: lab-sc-nfs # nome da classe de armazenamento que será utilizada
#  selector: # seletor de labels
#    matchLabels: # labels que serão utilizadas para selecionar o PV
#      storage: nfs # label que será utilizada para selecionar o PV
```

```bash
$ kubectl apply -f lab-pvc-nfs.yaml
persistentvolumeclaim/lab-pvc-nfs created

$ kubectl get pvc
NAME          STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
lab-pvc-nfs   Pending                                      lab-sc-nfs     <unset>                 20s
```

Para utilizar o volume que criamos no cluster, vamos criar o Pod avaixo utilizando o manifesto pod-pvc-teste.yaml.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - name: indexvolume
      mountPath: /usr/share/nginx/html
  volumes:
  - name: indexvolume
    persistentVolumeClaim:
      claimName: lab-pvc-nfs
```

Podemos ver abaixo a criação do Pod e a associação dele ao volume que criamos.

```bash
$ kubectl apply -f pod-pvc-teste.yaml
pod/nginx-pod created
$ kubectl get po nginx-pod
NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          30s
$ kubectl get sc
NAME         PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
lab-sc-nfs   kubernetes.io/no-provisioner   Retain          WaitForFirstConsumer   false                  16m
$ kubectl get pv
NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
lab-pv-nfs   1Gi        RWO            Retain           Bound    default/lab-pvc-nfs   lab-sc-nfs     <unset>                          16m
$ kubectl get pvc
NAME          STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
lab-pvc-nfs   Bound    lab-pv-nfs   1Gi        RWO            lab-sc-nfs     <unset>                 105s

$ kubectl describe pod nginx-pod
Name:             nginx-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             k8s-worker-01/192.168.15.241
Start Time:       Sun, 21 Dec 2025 01:23:37 +0000
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.40.0.1
IPs:
  IP:  10.40.0.1
Containers:
  nginx:
    Container ID:   containerd://606c4659c8ef9f5086211a44d31f7bebaeee3fbad4463a88f0a2665e124791eb
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:fb01117203ff38c2f9af91db1a7409459182a37c87cced5cb442d1d8fcc66d19
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 21 Dec 2025 01:23:39 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /usr/share/nginx/html from indexvolume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-5pmwz (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  indexvolume:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  lab-pvc-nfs
    ReadOnly:   false
  kube-api-access-5pmwz:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```

Agora para testar o funcionamento do mapeamento do NFS vamos criar um arquivo index.html no diretório compartilhado e verificar se o Nginx vai conseguir lear ele com sucesso.

```bash
/mnt/nfs# echo "FUNCIONOU LEGAL!" >> index.html
```

Conectando no container do Pod Nginx podemos ver que o arquivo foi criado no diretório da página web e pode ser acessada usando o comando curl.

```bash
$ kubectl exec -it nginx-pod -- bash
root@nginx-pod:/# cd /usr/share/nginx/html/
root@nginx-pod:/usr/share/nginx/html# ls
index.html
root@nginx-pod:/usr/share/nginx/html# cat index.html
FUNCIONOU LEGAL!
root@nginx-pod:/usr/share/nginx/html# curl localhost
FUNCIONOU LEGAL!
root@nginx-pod:/usr/share/nginx/html#
```

