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
