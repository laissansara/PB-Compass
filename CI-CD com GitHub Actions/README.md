# Projeto de CI/CD com GitHub Actions, ArgoCD e FastAPI

Este projeto é uma demonstração prática de um pipeline de automação completo, onde foram implementados os conceitos de **CI/CD (Integração e Entrega Contínua)** através da metodologia **GitOps**. O objetivo principal foi automatizar o ciclo completo de desenvolvimento, build, deploy e execução de uma aplicação FastAPI simples.

Através desta implementação, foi demonstrado como é possível entregar código com maior **velocidade, segurança e consistência**, eliminando processos manuais e propensos a erro. 
## Tecnologias Utilizadas

Cada ferramenta neste projeto desempenhou um papel específico na construção do pipeline de automação:

* **FastAPI (Python):** Serviu como a aplicação de exemplo. É um microserviço web leve, escolhido por sua simplicidade e performance.

* **Docker:** Foi a tecnologia de containerização utilizada para empacotar a aplicação FastAPI e todas as suas dependências em uma unidade padronizada e portátil: a **imagem Docker**. O `Dockerfile` no repositório da aplicação contém a "receita" para construir essa imagem.

* **GitHub Actions:** Atuou como o servidor de **CI (Integração Contínua)**. Integrado ao GitHub, ele automatizou os passos de build, teste e publicação da imagem Docker diretamente a partir dos commits no repositório.

* **Docker Hub:** Funcionou como nosso **Registro de Contêiner**, um repositório centralizado na nuvem para armazenar e distribuir as imagens Docker versionadas que foram geradas pelo GitHub Actions.

* **Kubernetes (via Rancher Desktop):** Foi o ambiente de orquestração de contêineres, simulando um ambiente de produção. Ele foi responsável por executar a aplicação de forma resiliente e escalável.

* **ArgoCD:** Foi a ferramenta de **CD (Entrega Contínua)** que implementou a metodologia GitOps. Ele garantiu que o estado do cluster Kubernetes fosse um reflexo fiel do que estava definido no repositório de manifestos, usando o Git como a única "fonte da verdade".

## Arquitetura e Fluxo de Trabalho Detalhado

A arquitetura do projeto foi desenhada para criar um fluxo contínuo e sem intervenção manual desde o código até a produção.

1.  **Repositório da Aplicação (`hello-app`):** O ponto de partida do fluxo. Contém o código-fonte da aplicação e a lógica da automação de CI.
    * **Repositório:** [laissansara/hello-app](https://github.com/laissansara/hello-app)

2.  **Repositório de Manifestos (`hello-manifests`):** O ponto central do GitOps. Contém a descrição declarativa do estado desejado da aplicação no Kubernetes.
    * **Repositório:** [laissansara/hello-manifests](https://github.com/laissansara/hello-manifests)

### O Fluxo Automatizado em Duas Fases

O processo de CI/CD foi acionado por um `git push` na branch `main` do `hello-app` e se dividiu em duas fases principais:

#### Fase 1: CI - Integração Contínua (Build e Publicação via GitHub Actions)

1.  **Gatilho:** Um desenvolvedor envia um novo commit para o repositório `hello-app`.
2.  **Build:** O workflow do GitHub Actions é acionado, fazendo o checkout do código.
3.  **Empacotamento:** A Action constrói uma nova imagem Docker usando o `Dockerfile`. A imagem é tagueada com o hash do commit do Git, garantindo rastreabilidade.
4.  **Publicação:** A nova imagem é enviada (push) para o registro no Docker Hub, usando credenciais armazenadas de forma segura nos GitHub Secrets.
5.  **A Ponte para o GitOps:** Este é o passo crucial. A Action clona o repositório `hello-manifests`, altera programaticamente o arquivo `deployment.yaml` para apontar para a nova tag de imagem, e faz um novo commit. Isso efetivamente declara: "a nova versão da aplicação que deve estar em produção é esta".

#### Fase 2: CD - Entrega Contínua (Sincronização via ArgoCD)

1.  **Detecção:** O ArgoCD, que está constantemente monitorando o `hello-manifests`, detecta o novo commit feito pelo GitHub Actions.
2.  **Comparação:** O ArgoCD compara o estado descrito nos manifestos do Git (o "estado desejado") com o que está atualmente rodando no cluster Kubernetes (o "estado atual"). Ele percebe que o cluster está rodando uma imagem antiga e, portanto, está `OutOfSync`.
3.  **Reconciliação (Deploy):** Como a política de sincronização foi configurada para `Automatic`, o ArgoCD inicia o processo de reconciliação. Ele puxa a nova imagem Docker do Docker Hub e atualiza o Deployment no Kubernetes, que por sua vez realiza um rolling update dos pods da aplicação para a nova versão, sem downtime.

## Ferramentas e Pré-requisitos Utilizados

Para a construção deste projeto, foram utilizados os seguintes pré-requisitos:
* Uma conta no GitHub (com os dois repositórios públicos).
* Uma conta no Docker Hub com um token de acesso.
* Rancher Desktop com Kubernetes habilitado.
* `kubectl` configurado corretamente para se comunicar com o cluster.
* ArgoCD instalado no cluster local.
* Git, Python 3 e Docker instalados na máquina local de desenvolvimento.

## Detalhes da Configuração Implementada

1.  **Configuração dos Segredos no GitHub (`hello-app`):**
    Para permitir que o workflow do GitHub Actions se autenticasse de forma segura em serviços externos, foram configurados os seguintes segredos no repositório `hello-app`:
    * `DOCKER_USERNAME` & `DOCKER_PASSWORD`: Para autenticação com o Docker Hub.
    * `SSH_PRIVATE_KEY`: Para autenticação com o repositório `hello-manifests` para realizar o commit automático.

2.  **Configuração da Chave de Deploy (`hello-manifests`):**
    Uma chave pública SSH foi adicionada ao repositório `hello-manifests` como uma "Deploy Key" com permissão de escrita. Isso segue o princípio de menor privilégio, garantindo que o workflow do `hello-app` tenha acesso apenas a este repositório específico.

3.  **Configuração da Aplicação no ArgoCD:**
    Uma nova aplicação foi criada na interface do ArgoCD, apontando para o repositório `hello-manifests`. A política de sincronização foi definida como `Automatic`, com as opções `Prune Resources` e `Self Heal` habilitadas, garantindo que o ArgoCD não apenas aplique novas mudanças, mas também remova recursos órfãos e reverta mudanças manuais no cluster, mantendo o Git como a autoridade máxima.

## Validação do Projeto

A validação do fluxo completo foi realizada da seguinte forma:

1.  **Alteração no Código:** Uma pequena modificação foi feita no arquivo `main.py` para alterar a mensagem de retorno da API.
2.  **Acionamento:** A alteração foi enviada ao GitHub com `git add`, `git commit` e `git push`.
3.  **Observação da Automação:**
    * **No GitHub:** Foi acompanhada a execução do workflow na aba "Actions", verificando os logs de build e push da imagem.
    * **No Docker Hub:** Foi confirmada a chegada da nova imagem com a tag do commit.
    * **No `hello-manifests`:** Foi verificado o novo commit feito pelo bot `github-actions[bot]`.
    * **No ArgoCD:** Foi observada a aplicação mudar de `Healthy` para `OutOfSync`, depois `Progressing`, e voltar para `Healthy` & `Synced`.
4.  **Validação Final:** O resultado foi validado acessando a aplicação via `kubectl port-forward`, confirmando que a nova mensagem estava no ar.

## Autora

* **Laís Sansara S. Silva** - [[laissansara]](https://github.com/laissansara)
