# Projeto: GitOps na Prática com Kubernetes e ArgoCD

## Descrição

O desenvolvimento moderno de aplicações exige entregas rápidas, seguras e escaláveis. Este projeto implementa um fluxo de trabalho **GitOps** completo, onde o Git é utilizado como para a infraestrutura e as aplicações. O objetivo foi implantar um conjunto de microserviços (a loja de e-commerce "Online Boutique") em um cluster Kubernetes local, com todo o processo de deploy sendo gerenciado de forma automatizada pelo ArgoCD.

## Tecnologias Utilizadas

* Kubernetes (via Rancher Desktop)
* Git & GitHub
* ArgoCD
* Docker
* kubectl

## Visão Geral da Arquitetura

A solução foi construída sobre três pilares principais:

* **GitHub:** Um repositório Git foi criado contendo apenas os manifestos YAML que descrevem o estado desejado da aplicação "Online Boutique".
* **Kubernetes (via Rancher Desktop):** Serviu como a plataforma de orquestração para executar os contêineres da aplicação de forma eficiente e resiliente. O Rancher Desktop forneceu um ambiente Kubernetes local completo para o desenvolvimento.
* **ArgoCD:** Foi a ferramenta de GitOps que conectou o repositório Git ao cluster Kubernetes. Sua função foi garantir continuamente que o estado real da aplicação no cluster espelhasse o estado declarado nos manifestos do Git.



## Estrutura do Repositório

A seguinte estrutura foi utilizada no repositório Git:

```
gitops-microservices/
└── k8s/
    └── online-boutique.yaml
```

* `online-boutique.yaml`: Um único arquivo de manifesto contendo a definição de todos os recursos Kubernetes (Deployments, Services, etc.) necessários para a aplicação "Online Boutique".

## Passos Detalhados da Execução

O projeto foi executado seguindo um roteiro metodológico, desde a preparação do ambiente até a validação final da aplicação.

### 1. Configuração do Ambiente e Pré-requisitos

O ambiente de desenvolvimento foi preparado com a instalação de todas as ferramentas necessárias no Arch Linux. A verificação final do ambiente foi feita com o comando `kubectl get nodes`, que confirmou a comunicação com o cluster Kubernetes provido pelo Rancher Desktop.

### 2. Preparação do Repositório Git (Definindo a Configuração)

Um novo repositório público (`gitops-microservices`) foi criado no GitHub para **servir como o repositório central da configuração**. Para garantir a limpeza e a aderência ao princípio do GitOps, apenas o manifesto da aplicação foi adicionado. O conteúdo do arquivo `release/kubernetes-manifests.yaml` do repositório original da Google foi copiado para o arquivo `k8s/online-boutique.yaml` dentro da estrutura recomendada.

### 3. Instalação do ArgoCD

O ArgoCD foi instalado no cluster Kubernetes através dos seguintes comandos:

```bash
# Criação de um namespace dedicado para o ArgoCD
kubectl create namespace argocd

# Aplicação do manifesto de instalação oficial
kubectl apply -n argocd -f [https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)
```

Aguardamos todos os pods do ArgoCD atingirem o estado `Running` e `READY 1/1` antes de prosseguir.

### 4. Acesso à Interface do ArgoCD

O acesso à interface web do ArgoCD foi estabelecido via `port-forward`. Durante este processo, um desafio técnico foi diagnosticado e resolvido:

* **Diagnóstico:** Análise dos logs do pod (`kubectl logs`) revelou que o servidor do ArgoCD estava rodando em modo inseguro (`tls: false`).
* **Solução:** O acesso foi feito via `http` em vez de `https`. O comando de `port-forward` mais estável foi o que se conectou diretamente ao pod, utilizando a porta padrão `8080`:
    ```bash
    # 1. Obter o nome do pod do servidor
    kubectl get pods -n argocd
    
    # 2. Conectar diretamente ao pod na porta 8080
    kubectl port-forward pod/<argocd-server-pod-name> -n argocd 8080:8080
    ```
A senha inicial foi recuperada do secret `argocd-initial-admin-secret` para permitir o login.
### 5. Criação da Aplicação no ArgoCD

Dentro da interface do ArgoCD, uma nova aplicação foi criada com as seguintes configurações principais:

* **Repository URL:** Apontando para o repositório `gitops-microservices` no GitHub.
* **Path:** `k8s`
* **Destination Namespace:** `online-boutique`
* **Auto-create namespace:** Habilitado para resolver erros de sincronização iniciais.

### 6. Sincronização e Validação Final

Com a aplicação criada, o ArgoCD iniciou a sincronização automática, criando todos os 35 recursos da aplicação no namespace `online-boutique`. Aguardamos o status da aplicação se tornar **Healthy** e **Synced**.

Para validar o sucesso do deploy, a interface da loja foi acessada. Como o serviço do frontend é do tipo `ClusterIP`, um novo `port-forward` foi necessário:

```bash
# Conecta a porta local 8081 ao serviço da loja
kubectl port-forward svc/frontend-external 8081:80 -n online-boutique
```

Acessando `http://localhost:8081`, a loja "Online Boutique" estava totalmente funcional.

## Desafios e Aprendizados

Durante a execução, diversos desafios técnicos foram encontrados e superados, proporcionando um aprendizado aprofundado:

* **Autenticação no Terminal:** A configuração inicial da autenticação do Git com o GitHub exigiu a criação de um Personal Access Token (PAT).
* **Diagnóstico de Conexão (Port-Forwarding):** Um erro persistente de SSL (`SSL_ERROR_RX_RECORD_TOO_LONG`) ao tentar acessar o ArgoCD exigiu uma investigação metódica. O problema foi diagnosticado ao analisar os logs do pod do `argocd-server`, que revelaram que ele estava rodando em modo `--insecure` (`tls: false`), exigindo uma conexão `http` em vez de `https`.
* **Ciclo de Vida dos Pods:** A descoberta de que os nomes dos pods no Kubernetes são efêmeros (mudam a cada reinicialização) foi um aprendizado prático fundamental, que nos ajudou a depurar erros de "pod not found".
* **Redefinição de Senha:** Devido a um estado de login inválido, foi necessário executar o procedimento oficial  de entrar com senha do `admin` diversas vezes.

## Resultado Final

Ao final do projeto, a aplicação de microserviços "Online Boutique" foi implantada com sucesso e acessada via navegador, validando todo o fluxo GitOps configurado. O estado da aplicação no cluster Kubernetes refletia perfeitamente a configuração declarada no repositório Git, cumprindo todos os objetivos propostos.


## Autores

* Laís Sansara Sampaio Silva
