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
* **Criação do Security Group:** Para a instância web, foi configurado o Security Group **`sgpublica`**. As regras de entrada foram definidas para permitir tráfego na `Porta 80 (HTTP)` e na `Porta 22 (SSH)`.
* **Lançamento da Instância EC2:** Uma instância foi lançada com as seguintes configurações:
    * **Nome:** `PROJETO LINUX PB`
    * **AMI:** Ubuntu Server 24.04 LTS
    * **Tipo de Instância:** `t3.micro`
    * **VPC e Sub-rede:** A instância foi alocada na VPC `vpc-lais`, especificamente na sub-rede pública `vpc-lais-subnet-public1-us-east-1a`.
    * **Security Group:** O grupo `sgpublica` foi associado para gerenciar o acesso.

### 2. Instalação e Configuração do Nginx

Com o acesso SSH estabelecido, os seguintes passos foram executados para instalar e configurar o servidor web na instância EC2.

**1. Instalação do Nginx:**
```bash
# Atualização dos pacotes e instalação do Nginx
sudo apt update && sudo apt install nginx -y
```

**2. Verificação do Serviço:**
```bash
# Verifica se o serviço do Nginx está ativo e habilitado
sudo systemctl status nginx
```

**3. Criação da Página de Status (`index.html`):**
```bash
# Comando para criar e editar a página no diretório padrão do Nginx
sudo nano /var/www/html/index.html
```
Dentro deste arquivo foi colado o código HTML/CSS customizado para exibir a página de status "Online" do servidor.

### 3. Configuração do Canal de Alertas (Telegram)

Para que o script pudesse enviar notificações, foi necessário configurar um bot no Telegram.

**1. Criação do Bot e Obtenção do `BOT_TOKEN`:**
   * Uma conversa foi iniciada com o `@BotFather` no Telegram e, com o comando `/newbot`, um novo bot foi registrado. Ao final, o BotFather forneceu o **`BOT_TOKEN`**.

**2. Obtenção do `CHAT_ID`:**
   * Após iniciar uma conversa com o novo bot, a URL `https://api.telegram.org/bot<SEU_BOT_TOKEN>/getUpdates` foi acessada para obter o **`CHAT_ID`** da conversa, localizado no caminho `message.chat.id` do JSON de resposta.

### 4. Implementação do Monitoramento

O coração do projeto é um sistema de monitoramento customizado, criado com um script em Bash e automatizado com Cron.

**1. O Script de Monitoramento (`monitor.sh`)**

O script abaixo foi salvo em `/home/ubuntu/scripts/monitor.sh` e tornado executável com `chmod +x`. Ele centraliza toda a lógica de verificação e alerta.

* **Código-Fonte:**
    ```bash
    #!/bin/bash

    # Configurações
    URL_SITE="http://<IP_PUBLICO_DA_INSTANCIA>"
    STATUS_ESPERADO=200
    LOG_FILE="/var/log/monitoramento.log"

    # Credenciais 
    BOT_TOKEN="SEU_BOT_TOKEN_AQUI"
    CHAT_ID="SEU_CHAT_ID_AQUI"

   
    TIMESTAMP=$(date "+%d/%m/%Y %H:%M:%S")
    STATUS_ATUAL=$(curl -s -o /dev/null -w "%{http_code}" "$URL_SITE")

    if [ "$STATUS_ATUAL" -eq "$STATUS_ESPERADO" ]; then
        MENSAGEM="[$TIMESTAMP] SUCESSO: Site $URL_SITE online. Status: $STATUS_ATUAL"
        echo "$MENSAGEM" >> "$LOG_FILE"
    else
        MENSAGEM_LOG="[$TIMESTAMP] FALHA: Site $URL_SITE indisponível. Status: $STATUS_ATUAL"
        echo "$MENSAGEM_LOG" >> "$LOG_FILE"

        MENSAGEM_TELEGRAM="🚨 *ALERTA DE SERVIÇO* 🚨%0A%0A*Origem:* Servidor AWS ☁️%0A*Site:* *$URL_SITE* indisponível!%0A%0A*Status Code:* $STATUS_ATUAL%0A*Horário:* $TIMESTAMP"
        URL_TELEGRAM="[https://api.telegram.org/bot$](https://api.telegram.org/bot$){BOT_TOKEN}/sendMessage"
        
        curl -s -X POST "$URL_TELEGRAM" -d chat_id="$CHAT_ID" -d text="$MENSAGEM_TELEGRAM" -d parse_mode="Markdown" > /dev/null
    fi
    ```

**2. Gerenciamento do Arquivo de Log**

Para manter um histórico das verificações e resolver questões de permissão do Cron, o arquivo de log foi criado e configurado manualmente:
```bash
sudo touch /var/log/monitoramento.log
sudo chown ubuntu:ubuntu /var/log/monitoramento.log
```

**3. Automação com Cron**

A tarefa foi agendada no `crontab` para executar o script a cada minuto com a seguinte regra:
`* * * * * /home/ubuntu/scripts/monitor.sh`

## Testes e Validação

Para validar a solução, foram executados os seguintes testes:

1.  **Teste de Sucesso:** Acessando o IP público da instância EC2 em um navegador, a página de status foi exibida com sucesso.
2.  **Teste de Falha:** O serviço do Nginx foi parado com `sudo systemctl stop nginx`. Em menos de um minuto, uma notificação de alerta foi recebida no Telegram.

## Autora

**Laís Sansara Sampaio Silva**

---
