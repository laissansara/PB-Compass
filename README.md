# Projeto: Configuração de Servidor Web com Monitoramento

## Objetivo

Implementar um ambiente de servidor web na nuvem da AWS, com um sistema de monitoramento contínuo que envia alertas em tempo real via Telegram em caso de falhas, garantindo a alta disponibilidade e a rápida resposta a incidentes.



## Tecnologias Utilizadas

* **Cloud:** Amazon Web Services (AWS)
* **Infraestrutura:** VPC, EC2, Security Groups, Internet Gateway
* **Servidor Web:** Nginx
* **Sistema Operacional:** Ubuntu Server
* **Linguagem:** Bash Script
* **Automação:** Cron
* **Notificações:** Telegram API

## Arquitetura
1.  **VPC (Virtual Private Cloud):** Uma rede privada nomeada **`vpc-lais`**  foi criada para isolar os recursos. A VPC contém **4 sub-redes**(duas públicas e duas privadas) distribuídas em Zonas de Disponibilidade distintas, garantindo alta disponibilidade.
2.  **Tabelas de Rotas e Gateway:** A VPC utiliza uma `tabela-publica` associada a um Internet Gateway (`gateway-vpc-lais`) para permitir acesso externo, e uma `tabela-privada` para recursos internos.
3.  **Security Groups:** Foram criados dois grupos para atuar como firewalls virtuais:
    * **`sgpublica`**: Associado à nossa instância EC2 para controlar o tráfego da web (HTTP) e o acesso administrativo (SSH).
    * **`sgprivada`**: Reservado para recursos futuros que não necessitem de acesso direto à internet.
4.  **Instância EC2:** Uma máquina virtual **Ubuntu do tipo `t3.micro`** onde o servidor Nginx e o script de monitoramento são executados.

## Passo a Passo da Implementação

### 1. Configuração do Ambiente na AWS

A infraestrutura foi provisionada diretamente no Console da AWS.

* **Criação da VPC e Sub-redes:** Foi criada a VPC **`vpc-lais`** com o bloco CIDR `10.0.0.0/16`, contendo duas sub-redes públicas e duas privadas, e o Internet Gateway **`gateway-vpc-lais`**.
* **Criação do Security Group:** Para a instância web, foi configurado o Security Group **`sgpublica`**. As regras de entrada foram definidas para permitir tráfego na `Porta 80 (HTTP)` de qualquer origem e na `Porta 22 (SSH)` de uma fonte segura.
* **Lançamento da Instância EC2:** Uma instância foi lançada com as seguintes configurações:
    * **Nome:** `PROJETO LINUX PB`
    * **AMI:** Ubuntu Server 24.04 LTS
    * **Tipo de Instância:** `t3.micro`
    * **VPC e Sub-rede:** A instância foi alocada na VPC `vpc-lais`, especificamente na sub-rede pública `vpc-lais-subnet-public1-us-east-1a`.
    * **Security Group:** O grupo `sgpublica` foi associado para gerenciar o acesso.

### 2. Instalação e Configuração do Nginx

Com o acesso SSH estabelecido, os seguintes passos foram executados para instalar e configurar o servidor web na instância EC2.

**1. Instalação do Nginx**
Primeiro, os pacotes do sistema foram atualizados e, em seguida, o Nginx foi instalado.

```bash
# Atualiza a lista de pacotes e atualiza o sistema
sudo apt update && sudo apt upgrade -y

# Instala o Nginx
sudo apt install nginx -y
```
**2. Verificação do Serviço**

Após a instalação, foi verificado se o serviço do Nginx estava ativo (`running`) e habilitado (`enabled`) para iniciar junto com o sistema, garantindo sua resiliência.

```bash
sudo systemctl status nginx
```
**3. Criação da Página de Status (`index.html`)**

Uma página de status personalizada foi criada para substituir a página padrão do Nginx.

```bash
# Comando para criar e editar a página no diretório padrão do Nginx
sudo nano /var/www/html/index.html
```
Dentro deste arquivo foi colado o código HTML/CSS customizado para exibir a página de status "Online" do servidor.

### 3. Implementação do Monitoramento

O coração do projeto é um sistema de monitoramento customizado, criado com um script em Bash e automatizado com Cron para garantir verificações contínuas.

**1. O Script de Monitoramento (`monitor.sh`)**

Foi desenvolvido um script em Bash para centralizar toda a lógica de verificação e alerta.

* **Funcionamento Principal:** O script utiliza o comando `curl` para fazer uma requisição HTTP ao servidor web. Ele foi configurado para extrair apenas o código de status da resposta (ex: `200` para sucesso, `502` para falha, etc.).
* **Lógica Condicional:** Um bloco `if/else` analisa o código de status:
    * **Se o status for `200 OK`**, o script entende que o site está saudável. Ele então formata uma mensagem de "SUCESSO", com data e hora, e a registra no arquivo de log. Nenhuma notificação é enviada para evitar ruído.
    * **Se o status for qualquer outro**, o script trata como uma falha. Ele registra uma mensagem de "FALHA" no log e, em seguida, constrói uma mensagem de alerta formatada para o Telegram. Essa mensagem inclui a origem do erro (Servidor AWS), o status code recebido e o horário, e é enviada via `curl` para a API do Bot do Telegram.

**2. Gerenciamento do Arquivo de Log**

Para manter um histórico de todas as verificações, foi configurado um arquivo de log.

* **Localização:** `/var/log/monitoramento.log`, seguindo as convenções de armazenamento de logs do Linux.
* **Criação e Permissão:** Foi identificado que o `cron` executa scripts de forma não-interativa e não consegue usar `sudo` para obter senhas. Para contornar isso, o arquivo de log foi criado manualmente com `sudo touch` e, em seguida, a propriedade do arquivo foi transferida para o usuário da instância (`ubuntu`) com `sudo chown`. Isso garante que o script, mesmo quando executado pelo `cron`, tenha permissão para escrever no log.

### 3. Configuração do Canal de Alertas (Telegram)

Para que o script pudesse enviar notificações, foi necessário configurar um bot no Telegram.

**1. Criação do Bot e Obtenção do `BOT_TOKEN`:**
   * Uma conversa foi iniciada com o `@BotFather` no Telegram.
   * Utilizando o comando `/newbot`, um novo bot foi criado, definindo seu nome e nome de usuário.
   * Ao final do processo, o BotFather forneceu o **`BOT_TOKEN`**, uma chave única de acesso à API, que foi armazenada com segurança.

**2. Obtenção do `CHAT_ID`:**
   * Para saber para qual conversa enviar a mensagem, foi necessário obter o `CHAT_ID`.
   * Primeiro, uma mensagem foi enviada para o bot recém-criado para iniciar uma conversa.
   * Em seguida, a seguinte URL foi acessada no navegador (substituindo o token):
     `https://api.telegram.org/bot<SEU_BOT_TOKEN>/getUpdates`
   * No resultado JSON, o ID foi localizado dentro da estrutura `message` -> `chat` -> `id`. Este número é o **`CHAT_ID`**

**4. Automação com Cron**

Para que o monitoramento fosse contínuo e autônomo, o agendador de tarefas `cron` foi utilizado.

* **Configuração:** O `crontab` do usuário foi editado com o comando `crontab -e`.
* **Regra de Agendamento:** Foi inserida a seguinte regra para executar o script a cada minuto de forma ininterrupta:
    ```
    * * * * * /home/ubuntu/scripts/monitor.sh
    ```
    Esta sintaxe garante que, independentemente da hora ou do dia, o script de verificação seja acionado, tornando o monitoramento um processo 24/7.

## Testes e Validação

Para validar a solução, foram executados os seguintes testes.

1.  **Teste de Sucesso:** Acessando o IP público da instância EC2 em um navegador, a página de status foi exibida com sucesso.
2.  **Teste de Falha:** O serviço do Nginx foi parado com `sudo systemctl stop nginx`. Em menos de um minuto, uma notificação de alerta foi recebida no Telegram.

## Autora

**Laís Sansara Sampaio Silva**

---
