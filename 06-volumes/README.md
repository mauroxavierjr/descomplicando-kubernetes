## Volumes no Kubernetes

### EmptyDir

É um tipo de volume criado durante a criação do Pod e é destruído quando o Pod é terminado. Não é um tipo de volume muito utilizado, um caso de uso seria quando você precisa compartilhar dados entre os containers de um Pod.

Abaixo temos um exemplo de um manifesto chamado pod-emptydir.yaml.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: giropops
spec:
  containers:
  - name: girus 
    image: ubuntu
    args: # argumentos que serão passados para o container
    - sleep # usando o comando sleep para manter o container em execução
    - infinity # o argumento infinity faz o container esperar para sempre
    volumeMounts: # lista de volumes que serão montados no container
    - name: primeiro-emptydir # nome do volume
      mountPath: /giropops # diretório onde o volume será montado 
  volumes: # lista de volumes
  - name: primeiro-emptydir # nome do volume
    emptyDir: # tipo do volume
      sizeLimit: 256Mi # tamanho máximo do volume
```