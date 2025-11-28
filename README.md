&nbsp;
## Resumo
Este repositório reúne meus arquivos e exercícios utilizados durante o estudo de Kubernetes. O objetivo é manter um conjunto organizado de manifests, anotações e pequenos experimentos que ajudem a revisar conceitos essenciais do ecossistema Kubernetes.
&nbsp;
## Objetivo do Repositório
- Consolidar exemplos práticos de objetos Kubernetes (Pods, Deployments, Services, ConfigMaps, Secrets, Volumes, Jobs, entre outros).
- Registrar pequenos desafios e testes utilizados para entender o comportamento do cluster.
- Manter anotações e referências que auxiliem no aprendizado contínuo.
- Servir como base para consultas rápidas e revisões.
&nbsp;
## Estrutura Geral
A organização pode variar conforme a evolução dos estudos, mas de modo geral cada diretório reúne:
- Manifests YAML utilizados no aprendizado.
- Exercícios práticos realizados ao longo dos capítulos/dias de estudo.
- Arquivos auxiliares usados em testes (scripts, HTMLs simples, imagens de teste).
- Notas e comentários para reforçar conceitos importantes.
&nbsp;
## Como Utilizar
- Leia as anotações incluídas em cada diretório para entender o contexto dos exemplos.
- Ajuste os manifests conforme necessário para o seu ambiente (minikube, kind, k3d ou cluster remoto).
- Execute os arquivos YAML com kubectl apply -f para observar o comportamento dos recursos.
- Utilize kubectl describe e kubectl logs para acompanhar o funcionamento dos objetos e entender eventuais erros.
&nbsp;
## Pré-requisitos
- kubectl instalado e configurado.
- Acesso a um cluster Kubernetes (local ou remoto).
- (Opcional) Ferramentas como docker, kind ou minikube para experimentos locais.
&nbsp;
## Observação
Este repositório não é voltado a produção. Os arquivos aqui armazenados têm finalidade exclusivamente educacional e podem conter configurações simplificadas ou não recomendadas para ambientes reais.


