#!/bin/bash

LOG_FILE="/var/log/auth.log"
OUTPUT_LOG="/var/log/login_attempts.log"  # Caminho para o log de tentativas
TELEGRAM_SCRIPT="/usr/local/bin/send_sms_telegram.sh"

# Inicializa o arquivo de log de tentativas se não existir
if [ ! -f "${OUTPUT_LOG}" ]; then
    touch "${OUTPUT_LOG}"
fi

# Variáveis para armazenar o último login e IP processados
LAST_LOGIN=""
LAST_IP=""
LAST_STATUS=""

inotifywait -m -e modify "${LOG_FILE}" | while read -r path action file; do
    # Captura a última linha do log
    LAST_LINE=$(tail -n 1 "${LOG_FILE}")

    # Verifica se há uma tentativa de login no auth.log
    if echo "${LAST_LINE}" | grep "sshd" > /dev/null; then
        # Extrai o login e o IP da linha de log
        LOGIN=$(echo "${LAST_LINE}" | grep -oP 'for \K[^ ]+')
        IP=$(echo "${LAST_LINE}" | grep -oP 'from \K[^ ]+')

        # Verifica o status da tentativa de login
        if echo "${LAST_LINE}" | grep "Failed password" > /dev/null; then
            STATUS="FALHA"
        elif echo "${LAST_LINE}" | grep "Accepted password" > /dev/null; then
            STATUS="SUCESSO"
        else
            STATUS="DESCONHECIDO"
        fi

        # Monta a mensagem para enviar via Telegram
        # PERSONALIZE SUA MENSAGEM AQUI! ====================================================#
        MESSAGE="Tentativa de login: $LOGIN de IP: $IP - Status: $STATUS"
        #====================================================================================#

        # Verifica se a tentativa é nova e se o status é FALHA ou DESCONHECIDO
        # Além disso, valida se LOGIN e IP não estão vazios
        if [[ ("$LOGIN" != "$LAST_LOGIN" || "$IP" != "$LAST_IP") && ("$STATUS" == "FALHA" || "$STATUS" == "DESCONHECIDO") && -n "$LOGIN" && -n "$IP" ]]; then
            # Registra a tentativa no log de saída
            echo "$(date): $MESSAGE" >> "${OUTPUT_LOG}"

            # Executa o script para enviar mensagem via Telegram
            if ! bash "${TELEGRAM_SCRIPT}" "${MESSAGE}"; then
                echo "Erro ao enviar mensagem via Telegram." >> "${OUTPUT_LOG}"
            fi

            # Atualiza as variáveis de último login e IP
            LAST_LOGIN="$LOGIN"
            LAST_IP="$IP"
            LAST_STATUS="$STATUS"
        fi
    fi
done

