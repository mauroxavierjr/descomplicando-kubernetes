## Criação do Cluster Kubernetes com kubeadm

### Pré-Requisitos

* Linux

* 2 GB ou mais de RAM por máquina (menos de 2 GB não é recomendado)

* 2 CPUs ou mais

* Conexão de rede entre todas os nodes no cluster (pode ser via rede pública ou privada)

* Algumas portas precisam estar abertas para que o cluster funcione corretamente, as principais:

    * Porta 6443: É a porta padrão usada pelo Kubernetes API Server para se comunicar com os componentes do cluster. É a porta principal usada para gerenciar o cluster e deve estar sempre aberta.

    * Portas 10250-10255: Essas portas são usadas pelo kubelet para se comunicar com o control plane do Kubernetes. A porta 10250 é usada para comunicação de leitura/gravação e a porta 10255 é usada apenas para comunicação de leitura.

    * Porta 30000-32767: Essas portas são usadas para serviços NodePort que precisam ser acessíveis fora do cluster. O Kubernetes aloca uma porta aleatória dentro desse intervalo para cada serviço NodePort e redireciona o tráfego para o pod correspondente.

    * Porta 2379-2380: Essas portas são usadas pelo etcd, o banco de dados de chave-valor distribuído usado pelo control plane do Kubernetes. A porta 2379 é usada para comunicação de leitura/gravação e a porta 2380 é usada apenas para comunicação de eleição.

### Instalação - Control Plane


#### 01 - Desativação da Swap

O Kubernetes não trabalha em servidores com a swap ativa.

```bash
sudo swapoff -a
```

Importante também verificar o arquivo /etc/fstab e remover as linhas referentes a swap.
Se existir uma entrada de swap no arquivo, execute o comando abaixo para aplicar as mudanças.

```bash
mount -a
```

#### 02 - Carregando os módulos do Kernel

Carregar os módulos do kernal necessários para o funcionamento do Kubernetes.

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

#### 03 - Configurando parâmetros do sistema

configurar alguns parâmetros do sistema. Isso garantirá que nosso cluster funcione corretamente.

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

#### 04 - Instalando os pacotes do Kubernetes

Configuração do repositório do Kubernetes e instalação dos pacotes necessários

```bash
sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
```

#### 05 - Instalando o containerd

Instalação do containerd, que são essenciais para nosso ambiente Kubernetes.

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && sudo apt-get install -y containerd.io
```

#### 06 - Configurando o containerd

Configurar o containerd para que ele funcione adequadamente com o nosso cluster.

```bash
sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl status containerd
```

#### 07 - Habilitando o serviço do kubelet

Habilitar o serviço do kubelet para que ele inicie automaticamente com o sistema:

```bash
sudo systemctl enable --now kubelet
```

#### 08 - Inicializando o cluster

Inicialização do cluster. Essa etapa deve ser executada no servidor que será o nosso Control PLane.

```bash
sudo kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=<O IP QUE VAI FALAR COM OS NODES>
```

Se tudor der certo essa será a saída do comando.

```bash
[init] Using Kubernetes version: v1.34.3
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-controlplane-01 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.15.240]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s-controlplane-01 localhost] and IPs [192.168.15.240 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s-controlplane-01 localhost] and IPs [192.168.15.240 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "super-admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/instance-config.yaml"
[patches] Applied patch of type "application/strategic-merge-patch+json" to target "kubeletconfiguration"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 502.470905ms
[control-plane-check] Waiting for healthy control plane components. This can take up to 4m0s
[control-plane-check] Checking kube-apiserver at https://192.168.15.240:6443/livez
[control-plane-check] Checking kube-controller-manager at https://127.0.0.1:10257/healthz
[control-plane-check] Checking kube-scheduler at https://127.0.0.1:10259/livez
[control-plane-check] kube-controller-manager is healthy after 2.507961697s
[control-plane-check] kube-scheduler is healthy after 2.645438777s
[control-plane-check] kube-apiserver is healthy after 9.001570536s
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s-controlplane-01 as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8s-controlplane-01 as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: sqmj1c.cydsysuage75u1os
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.15.240:6443 --token sqmj1c.cydsysuage75u1os \
        --discovery-token-ca-cert-hash sha256:a551d866945d086c5631c80b6d770048949f5e194e99b6ec98c8386dbd912531
```

Essa saída possui informações importantes para a continuidade da configuração do cluster. Um deles são os comandos abaixo que configura o kubeconfig. Essa configuração é necessária para que o kubectl possa se comunicar com o cluster, pois quando estamos copiando o arquivo admin.conf para o diretório .kube do usuário, estamos copiando o arquivo com as permissões de root, esse é o motivo de executarmos o comando sudo chown $(id -u):$(id -g) $HOME/.kube/config para alterar as permissões do arquivo para o usuário que está executando o comando.

```bash
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### Entendendo o arquivo admin.conf
Vamos entender o que temos dentro do arquivo admin.conf. Antes de mais nada precisamos conhecer alguns pontos importantes sobre o a estrutura do arquivo admin.conf:

* É um arquivo de configuração do kubectl, que é o cliente de linha de comando do Kubernetes. Ele é usado para se comunicar com o cluster Kubernetes.

* Contém as informações de acesso ao cluster, como o endereço do servidor API, o certificado de cliente e o token de autenticação.

* Eu posso ter mais de um contexto dentro do arquivo admin.conf, onde cada contexto é um cluster Kubernetes. Por exemplo, eu posso ter um contexto para o cluster de produção e outro para o cluster de desenvolvimento, simples como voar.

* Ele contém os dados de acesso ao cluster, portanto, se alguém tiver acesso a esse arquivo, ele terá acesso ao cluster. (Desde que tenha acesso ao cluster).

* O arquivo admin.conf é criado quando o cluster é inicializado.

Vou copiar aqui o conteúdo de um exemplo de arquivo admin.conf:

```bash
apiVersion: v1
# Informações do cluster e hash do certificado da CA do cluster
clusters:
- cluster:
    certificate-authority-data: <HASH DA CA DO CLUSTER>
    server: https://192.168.15.240:6443
  name: kubernetes
# Definição do contexto específico para cada cluster, usuário ou namespace
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
# Contexto atual
current-context: kubernetes-admin@kubernetes
kind: Config
# Informações sobre os usuários e suas credenciais para acessar os clusters. Neste arquivo, há somente um usuário chamado kubernetes-admin. Ele contém os dados do certificado de cliente e da chave do cliente.
users:
- name: kubernetes-admin
  user:
    client-certificate-data: <HASH DA CHAVE PÚBLICA DO USUÁRIO>
    client-key-data: <HASH DA CHAVE PRIVADA DO USUÁRIO>
```

Outra informação super importante que está contida nesse arquivo é referente as credenciais de acesso ao cluster. Essas credenciais são usadas para autenticar o usuário que está executando o comando kubectl. Essas credenciais são:

* Token de autenticação: É um token de acesso que é usado para autenticar o usuário que está executando o comando kubectl. Esse token é gerado automaticamente quando o cluster é inicializado. Esse token é usado para autenticar o usuário que está executando o comando kubectl. Esse token é gerado automaticamente quando o cluster é inicializado.

* certificate-authority-data: Este campo contém a representação em base64 do certificado da autoridade de certificação (CA) do cluster. A CA é responsável por assinar e emitir certificados para o cluster. O certificado da CA é usado para verificar a autenticidade dos certificados apresentados pelo servidor de API e pelos clientes, garantindo que a comunicação entre eles seja segura e confiável.

* client-certificate-data: Este campo contém a representação em base64 do certificado do cliente. O certificado do cliente é usado para autenticar o usuário ao se comunicar com o servidor de API do Kubernetes. O certificado é assinado pela autoridade de certificação (CA) do cluster e inclui informações sobre o usuário e sua chave pública.

* client-key-data: Este campo contém a representação em base64 da chave privada do cliente. A chave privada é usada para assinar as solicitações enviadas ao servidor de API do Kubernetes, permitindo que o servidor verifique a autenticidade da solicitação. A chave privada deve ser mantida em sigilo e não compartilhada com outras pessoas ou sistemas.

Esses campos são importantes para estabelecer uma comunicação segura e autenticada entre o cliente (geralmente o kubectl ou outras ferramentas de gerenciamento) e o servidor de API do Kubernetes. Eles permitem que o servidor de API verifique a identidade do cliente e vice-versa, garantindo que apenas usuários e sistemas autorizados possam acessar e gerenciar os recursos do cluster.

Você pode encontrar os arquivos que são utilizados para adicionar essas credentiais ao seu cluster em /etc/kubernetes/pki/. Lá temos os seguintes arquivos que são utilizados para adicionar essas credenciais ao seu cluster:

* client-certificate-data: O arquivo de certificado do cliente geralmente é encontrado em /etc/kubernetes/pki/apiserver-kubelet-client.crt.

* client-key-data: O arquivo da chave privada do cliente geralmente é encontrado em /etc/kubernetes/pki/apiserver-kubelet-client.key.

* certificate-authority-data: O arquivo do certificado da autoridade de certificação (CA) geralmente é encontrado em /etc/kubernetes/pki/ca.crt.

Vale lembrar que esse arquivo é gerado automaticamente quando o cluster é inicializado, e são adicionados ao arquivo admin.conf que é utilizado para acessar o cluster. Essas credenciais são copiadas para o arquivo admin.conf já convertidas para base64.

Caso você queira, você pode acessar o conteúdo do arquivo admin.conf com o seguinte comando:

```bash
kubectl config view
```

### Instalação - Workers

Repita os passos 1, 2, 3, 4, 5 e 6 nos servidores que serão o workers do cluster.
Ao fim execute o comando de join informado na saída do init de configuração do Control Plane.

```bash
kubeadm join 192.168.15.240:6443 --token sqmj1c.cydsysuage75u1os \
        --discovery-token-ca-cert-hash sha256:a551d866945d086c5631c80b6d770048949f5e194e99b6ec98c8386dbd912531
```

Vamos analisar as partes do comando fornecido:

* kubeadm join: O comando base para adicionar um novo nó ao cluster.

* 172.31.57.89:6443: Endereço IP e porta do servidor de API do nó mestre (control plane). Neste exemplo, o nó mestre está localizado no IP 172.31.57.89 e a porta é 6443.

* --token if9hn9.xhxo6s89byj9rsmd: O token é usado para autenticar o nó trabalhador no nó mestre durante o processo de adesão. Os tokens são gerados pelo nó mestre e têm uma validade limitada (por padrão, 24 horas). Neste exemplo, o token é if9hn9.xhxo6s89byj9rsmd.

* --discovery-token-ca-cert-hash sha256:ad583497a4171d1fc7d21e2ca2ea7b32bdc8450a1a4ca4cfa2022748a99fa477: Este é um hash criptográfico do certificado da autoridade de certificação (CA) do control plane. Ele é usado para garantir que o nó worker esteja se comunicando com o nó do control plane correto e autêntico. O valor após sha256: é o hash do certificado CA.

### Instalação do Weave Net

Instalação do Weave Net.

```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```

Aguarde alguns minutos até que todos os componentes do cluster estejam em funcionamento. Você pode verificar o status dos componentes do cluster com o seguinte comando:

```bash
kubectl get pods -n kube-system
NAME                                          READY   STATUS    RESTARTS      AGE
coredns-66bc5c9577-7xmkr                      1/1     Running   0             83m
coredns-66bc5c9577-jm4pg                      1/1     Running   0             83m
etcd-k8s-controlplane-01                      1/1     Running   0             83m
kube-apiserver-k8s-controlplane-01            1/1     Running   0             83m
kube-controller-manager-k8s-controlplane-01   1/1     Running   0             83m
kube-proxy-cfwbk                              1/1     Running   0             80m
kube-proxy-f9zb2                              1/1     Running   0             75m
kube-proxy-lsjcl                              1/1     Running   0             83m
kube-scheduler-k8s-controlplane-01            1/1     Running   0             83m
weave-net-9b6nz                               2/2     Running   1 (74m ago)   75m
weave-net-dkkrq                               2/2     Running   1 (74m ago)   75m
weave-net-sqs88                               2/2     Running   1 (74m ago)   75m

```
 
```bash
kubectl get node
NAME                  STATUS   ROLES           AGE   VERSION
k8s-controlplane-01   Ready    control-plane   52m   v1.34.3
k8s-worker-01         Ready    <none>          50m   v1.34.3
k8s-worker-02         Ready    <none>          44m   v1.34.3
```

O Weave Net é um plugin de rede que permite que os pods se comuniquem entre si. Ele também permite que os pods se comuniquem com o mundo externo, como outros clusters ou a Internet. Quando o Kubernetes é instalado, ele resolve vários problemas por si só, porém quando o assunto é a comunicação entre os pods, ele não resolve. Por isso, precisamos instalar um plugin de rede para resolver esse problema.

#### O que é o CNI?

CNI é uma especificação e conjunto de bibliotecas para a configuração de interfaces de rede em containers. A CNI permite que diferentes soluções de rede sejam integradas ao Kubernetes, facilitando a comunicação entre os Pods (grupos de containers) e serviços.

Com isso, temos diferentes plugins de redes, que seguem a especificação CNI, e que podem ser utilizados no Kubernetes. O Weave Net é um desses plugins de rede.

Entre os plugins de rede mais utilizados no Kubernetes, temos:

* Calico é um dos plugins de rede mais populares e amplamente utilizados no Kubernetes. Ele fornece segurança de rede e permite a implementação de
políticas de rede. O Calico utiliza o BGP (Border Gateway Protocol) para rotear tráfego entre os nós do cluster, proporcionando um desempenho eficiente e escalável.

* Flannel é um plugin de rede simples e fácil de configurar, projetado para o Kubernetes. Ele cria uma rede overlay que permite que os Pods se comuniquem entre si, mesmo em diferentes nós do cluster. O Flannel atribui um intervalo de IPs a cada nó e utiliza um protocolo simples para rotear o tráfego entre os nós.

* Weave é outra solução popular de rede para Kubernetes. Ele fornece uma rede overlay que permite a comunicação entre os Pods em diferentes nós. Além disso, o Weave suporta criptografia de rede e gerenciamento de políticas de rede. Ele também pode ser integrado com outras soluções, como o Calico, para fornecer recursos adicionais de segurança e políticas de rede.

* Cilium é um plugin de rede focado em segurança e desempenho. Ele utiliza o BPF (Berkeley Packet Filter) para fornecer políticas de rede e segurança de alto desempenho. O Cilium também oferece recursos avançados, como balanceamento de carga, monitoramento e solução de problemas de rede.

* Kube-router é uma solução de rede leve para Kubernetes. Ele utiliza o BGP e IPVS (IP Virtual Server) para rotear o tráfego entre os nós do cluster, proporcionando um desempenho eficiente e escalável. Kube-router também suporta políticas de rede e permite a implementação de firewalls entre os Pods.

Esses são apenas alguns dos plugins de rede mais populares e amplamente utilizados no Kubernetes. Você pode encontrar uma lista completa de plugins de rede no site do Kubernetes.

#### Realizando Testes do Cluster

Criando um Deployment de teste.

```bash
kubectl get po -A -owide
NAMESPACE     NAME                                          READY   STATUS    RESTARTS       AGE    IP               NODE                  NOMINATED NODE   READINESS GATES
default       nginx-66686b6766-69t8w                        1/1     Running   0              28s    10.32.0.2        k8s-worker-02         <none>           <none>
default       nginx-66686b6766-ht6sx                        1/1     Running   0              28s    10.32.0.3        k8s-worker-02         <none>           <none>
default       nginx-66686b6766-kb57j                        1/1     Running   0              28s    10.40.0.1        k8s-worker-01         <none>           <none>
kube-system   coredns-66bc5c9577-7xmkr                      1/1     Running   0              121m   10.38.0.2        k8s-controlplane-01   <none>           <none>
kube-system   coredns-66bc5c9577-jm4pg                      1/1     Running   0              121m   10.38.0.1        k8s-controlplane-01   <none>           <none>
kube-system   etcd-k8s-controlplane-01                      1/1     Running   0              121m   192.168.15.240   k8s-controlplane-01   <none>           <none>
kube-system   kube-apiserver-k8s-controlplane-01            1/1     Running   0              121m   192.168.15.240   k8s-controlplane-01   <none>           <none>
kube-system   kube-controller-manager-k8s-controlplane-01   1/1     Running   0              121m   192.168.15.240   k8s-controlplane-01   <none>           <none>
kube-system   kube-proxy-cfwbk                              1/1     Running   0              118m   192.168.15.241   k8s-worker-01         <none>           <none>
kube-system   kube-proxy-f9zb2                              1/1     Running   0              113m   192.168.15.242   k8s-worker-02         <none>           <none>
kube-system   kube-proxy-lsjcl                              1/1     Running   0              121m   192.168.15.240   k8s-controlplane-01   <none>           <none>
kube-system   kube-scheduler-k8s-controlplane-01            1/1     Running   0              121m   192.168.15.240   k8s-controlplane-01   <none>           <none>
kube-system   weave-net-9b6nz                               2/2     Running   1 (112m ago)   113m   192.168.15.241   k8s-worker-01         <none>           <none>
kube-system   weave-net-dkkrq                               2/2     Running   1 (112m ago)   113m   192.168.15.240   k8s-controlplane-01   <none>           <none>
kube-system   weave-net-sqs88                               2/2     Running   1 (112m ago)   113m   192.168.15.242   k8s-worker-02         <none>           <none>
```

Visualizando os nodes.

```bash
kubectl get nodes -owide
NAME                  STATUS   ROLES           AGE    VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-controlplane-01   Ready    control-plane   125m   v1.34.3   192.168.15.240   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://2.2.0
k8s-worker-01         Ready    <none>          122m   v1.34.3   192.168.15.241   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://2.2.0
k8s-worker-02         Ready    <none>          117m   v1.34.3   192.168.15.242   <none>        Ubuntu 24.04.3 LTS   6.8.0-90-generic   containerd://2.2.0
```

Visualizando detalhes de um node.

```bash
kubectl describe node k8s-controlplane-01
Name:               k8s-controlplane-01
Roles:              control-plane
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=k8s-controlplane-01
                    kubernetes.io/os=linux
                    node-role.kubernetes.io/control-plane=
                    node.kubernetes.io/exclude-from-external-load-balancers=
Annotations:        node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Tue, 16 Dec 2025 22:28:32 +0000
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Unschedulable:      false
Lease:
  HolderIdentity:  k8s-controlplane-01
  AcquireTime:     <unset>
  RenewTime:       Wed, 17 Dec 2025 00:34:57 +0000
Conditions:
  Type                 Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----                 ------  -----------------                 ------------------                ------                       -------
  NetworkUnavailable   False   Tue, 16 Dec 2025 22:37:25 +0000   Tue, 16 Dec 2025 22:37:25 +0000   WeaveIsUp                    Weave pod has set this
  MemoryPressure       False   Wed, 17 Dec 2025 00:30:33 +0000   Tue, 16 Dec 2025 22:28:31 +0000   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure         False   Wed, 17 Dec 2025 00:30:33 +0000   Tue, 16 Dec 2025 22:28:31 +0000   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure          False   Wed, 17 Dec 2025 00:30:33 +0000   Tue, 16 Dec 2025 22:28:31 +0000   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready                True    Wed, 17 Dec 2025 00:30:33 +0000   Tue, 16 Dec 2025 22:37:06 +0000   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:  192.168.15.240
  Hostname:    k8s-controlplane-01
Capacity:
  cpu:                2
  ephemeral-storage:  11758760Ki
  hugepages-2Mi:      0
  memory:             2014968Ki
  pods:               110
Allocatable:
  cpu:                2
  ephemeral-storage:  10836873199
  hugepages-2Mi:      0
  memory:             1912568Ki
  pods:               110
System Info:
  Machine ID:                 ec364030abf24d4892774fc716d9f108
  System UUID:                b8eca071-b24d-3b4a-861d-b3c8d46e4fea
  Boot ID:                    1bb17f48-b4a9-4f4c-9a19-1639d0a5a2da
  Kernel Version:             6.8.0-90-generic
  OS Image:                   Ubuntu 24.04.3 LTS
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  containerd://2.2.0
  Kubelet Version:            v1.34.3
  Kube-Proxy Version:
PodCIDR:                      10.10.0.0/24
PodCIDRs:                     10.10.0.0/24
Non-terminated Pods:          (8 in total)
  Namespace                   Name                                           CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                                           ------------  ----------  ---------------  -------------  ---
  kube-system                 coredns-66bc5c9577-7xmkr                       100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)     126m
  kube-system                 coredns-66bc5c9577-jm4pg                       100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)     126m
  kube-system                 etcd-k8s-controlplane-01                       100m (5%)     0 (0%)      100Mi (5%)       0 (0%)         126m
  kube-system                 kube-apiserver-k8s-controlplane-01             250m (12%)    0 (0%)      0 (0%)           0 (0%)         126m
  kube-system                 kube-controller-manager-k8s-controlplane-01    200m (10%)    0 (0%)      0 (0%)           0 (0%)         126m
  kube-system                 kube-proxy-lsjcl                               0 (0%)        0 (0%)      0 (0%)           0 (0%)         126m
  kube-system                 kube-scheduler-k8s-controlplane-01             100m (5%)     0 (0%)      0 (0%)           0 (0%)         126m
  kube-system                 weave-net-dkkrq                                100m (5%)     0 (0%)      0 (0%)           0 (0%)         118m
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                950m (47%)   0 (0%)
  memory             240Mi (12%)  340Mi (18%)
  ephemeral-storage  0 (0%)       0 (0%)
  hugepages-2Mi      0 (0%)       0 (0%)
Events:              <none>
```bash
