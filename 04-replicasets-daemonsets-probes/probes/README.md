## O que são probes?

Probes são uma forma de monitorar o Pod para saber se ele está saudável ou não. Existem três tipos de probes no Kubernetes:

Liveness: Verificar se o Pod está vivo e saudável.
Readness: Determina se o Pod está apto a receber tráfego
Startup: Verifica se o Pod está pronto para iniciar

A imagem abaixo resume de forma simples e clara a diferença entre cada uma das probes.

![Diferenças entre as probes do Kubernetes](./images/probes.png)