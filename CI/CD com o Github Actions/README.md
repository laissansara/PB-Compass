# Projeto de CI/CD com GitHub Actions, ArgoCD e FastAPI

Este projeto demonstra a implementação de um pipeline completo de CI/CD (Integração e Entrega Contínua) utilizando a metodologia GitOps. O objetivo é automatizar todo o ciclo de vida de uma aplicação web simples, desde o commit do código até a implantação em um cluster Kubernetes local.

O pipeline foi construído para entregar código com **velocidade, segurança e consistência**, práticas essenciais no ecossistema de DevOps moderno.

## Tecnologias Utilizadas

* **Aplicação:** FastAPI (Python)
* **Contêineres:** Docker
* **CI/CD (Automação):** GitHub Actions
* **Registro de Contêiner:** Docker Hub
* **Orquestração:** Kubernetes (via Rancher Desktop)
* **Entrega Contínua (GitOps):** ArgoCD

## Arquitetura e Fluxo de Trabalho

O projeto é baseado em dois repositórios Git e um fluxo de trabalho totalmente automatizado:

1.  **Repositório da Aplicação (`hello-app`):** Contém o código-fonte da aplicação FastAPI, o `Dockerfile` para a containerização e o workflow do GitHub Actions (`.github/workflows/`).

2.  **Repositório de Manifestos (`hello-manifests`):** Atua como a única "fonte da verdade" (Source of Truth) para o nosso ambiente. Contém os manifestos do Kubernetes (`deployment.yaml` e `service.yaml`) que descrevem o estado desejado da aplicação.

### O Fluxo Automatizado

O processo de CI/CD é acionado por um `git push` na branch `main` do repositório da aplicação:

1.  **Trigger:** O desenvolvedor envia um novo commit para o repositório `hello-app`.
2.  **CI (GitHub Actions):**
    * A pipeline do GitHub Actions é iniciada.
    * Uma imagem Docker da aplicação é construída a partir do `Dockerfile`.
    * A nova imagem é enviada para o Docker Hub com uma tag única (o hash do commit).
    * A pipeline automaticamente clona o repositório `hello-manifests` e atualiza o arquivo `deployment.yaml` com a nova tag da imagem.
    * Um novo commit é enviado para o `hello-manifests` com esta atualização.
3.  **CD (ArgoCD):**
    * O ArgoCD, que está monitorando o repositório `hello-manifests`, detecta a mudança no `deployment.yaml`.
    * Ele identifica que o estado do cluster está defasado em relação ao estado desejado no Git.
    * O ArgoCD automaticamente puxa a nova imagem do Docker Hub e atualiza o deploy no cluster Kubernetes, completando o ciclo.

## Pré-requisitos

Para replicar este projeto, você precisará de:
* Uma conta no GitHub (com os dois repositórios públicos).
* Uma conta no Docker Hub com um token de acesso.
* Rancher Desktop com Kubernetes habilitado.
* `kubectl` configurado corretamente.
* ArgoCD instalado no cluster local.
* Git, Python 3 e Docker instalados na sua máquina local.

## Configuração

1.  **Clone os Repositórios:**
    ```bash
    # Repositório da aplicação
    git clone [https://github.com/](https://github.com/)[SEU-USUARIO-GITHUB]/hello-app.git

    # Repositório dos manifestos
    git clone [https://github.com/](https://github.com/)[SEU-USUARIO-GITHUB]/hello-manifests.git
    ```

2.  **Configure os Segredos no GitHub:**
    No repositório `hello-app`, vá para `Settings > Secrets and variables > Actions` e configure os seguintes segredos:
    * `DOCKER_USERNAME`: Seu nome de usuário do Docker Hub.
    * `DOCKER_PASSWORD`: Seu token de acesso do Docker Hub.
    * `SSH_PRIVATE_KEY`: A chave SSH privada usada para dar permissão de escrita ao repositório `hello-manifests`.

3.  **Configure a Chave de Deploy:**
    No repositório `hello-manifests`, vá para `Settings > Deploy keys` e adicione a chave SSH pública correspondente, garantindo que a permissão de escrita ("Allow write access") esteja habilitada.

4.  **Configure a Aplicação no ArgoCD:**
    * Acesse a interface do ArgoCD.
    * Crie uma nova aplicação (`+ New App`) apontando para a URL do seu repositório `hello-manifests`.
    * Configure a política de sincronização como `Automatic` para que as atualizações sejam aplicadas sem intervenção manual.

## Testando o Pipeline

Para testar o fluxo completo:

1.  Faça uma pequena alteração no arquivo `main.py` no repositório `hello-app`.
2.  Envie a alteração para o GitHub:
    ```bash
    git add main.py
    git commit -m "Teste de pipeline"
    git push origin main
    ```
3.  Observe a pipeline ser executada na aba "Actions" do GitHub e, em seguida, observe o Argo CD sincronizar a nova versão na sua interface.
4.  Acesse a aplicação (via `kubectl port-forward`) para verificar se a sua alteração está no ar.

## ✒️ Autor

* **Laís Sansara S. Silva** - 
