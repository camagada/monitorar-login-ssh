#!/bin/bash

# Atualizar e instalar os aplicativos necessários
echo "==============================================="
echo "Atualizando pacotes e instalando dependências..."
apt update && apt upgrade -y
apt install inotify-tools -y
apt install rsyslog -y

# Cores para facilitar a visualização
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RESET='\033[0m' # Reseta a cor para o padrão

# Solicitar informações do usuário para configurar o Telegram
echo -e "\n${GREEN}== Configuração do Telegram ==${RESET}"
echo -e "${BLUE}Informe os valores para configurar o envio de mensagens no Telegram.${RESET}\n"

read -p "Informe o BOT_TOKEN do Telegram: " BOT_TOKEN
read -p "Informe o CHAT_ID do Telegram: " CHAT_ID

# Criar o arquivo /usr/local/bin/send_sms_telegram.sh
echo "==============================================="
echo "Criando /usr/local/bin/send_sms_telegram.sh..."
cat <<EOF > /usr/local/bin/send_sms_telegram.sh
#!/bin/bash

BOT_TOKEN="${BOT_TOKEN}"
CHAT_ID="${CHAT_ID}"

# A mensagem vem do monitor_login.sh
MESSAGE=\$1

curl -s -X POST "https://api.telegram.org/bot\${BOT_TOKEN}/sendMessage" \\
    -d chat_id="\${CHAT_ID}" \\
    -d text="\${MESSAGE}"
EOF

echo "==============================================="
# Exibir o título e descrição com cores
echo -e "\n${GREEN}== Informe o nome do Servidor ==${RESET}"
echo -e "${BLUE}Informe o nome do Servidor para aparecer no LOG da mensagem do Telegram.${RESET}\n"

# Solicitar o nome do servidor com mensagem colorida
read -p "$(echo -e "${GREEN}Informe o nome do Servidor: ${RESET}")" NOME_SERVIDOR

# Criar o arquivo /usr/local/bin/monitor_login.sh
echo "==============================================="
echo "Criando /usr/local/bin/monitor_login.sh..."
cat <<EOF > /usr/local/bin/monitor_login.sh
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
        MESSAGE="Servidor: ${NOME_SERVIDOR} - Tentativa de login: $LOGIN de IP: $IP - Status: $STATUS"

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
EOF

# Criar o arquivo /etc/systemd/system/monitor-login.service
echo "Criando /etc/systemd/system/monitor-login.service..."
cat <<EOF > /etc/systemd/system/monitor-login.service
[Service]
ExecStart=/usr/local/bin/monitor_login.sh
Restart=on-failure
RestartSec=5
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Ajustar permissões dos arquivos criados
echo "Ajustando permissões dos arquivos..."
chmod +x /usr/local/bin/send_sms_telegram.sh
chmod +x /usr/local/bin/monitor_login.sh
chmod 644 /etc/systemd/system/monitor-login.service

# Ativar e iniciar o serviço monitor-login
echo "Ativando e iniciando o serviço monitor-login..."
systemctl daemon-reload
systemctl enable monitor-login.service
systemctl start monitor-login.service

# Mostrar o status do serviço
echo "==============================================="
echo "Verificando o status do serviço monitor-login:"
SERVICE_STATUS=$(systemctl is-active monitor-login.service)
if [ "$SERVICE_STATUS" == "active" ]; then
    echo -e "\e[32mO serviço monitor-login está ativo e em execução.\e[0m"
else
    echo -e "\e[33mExibindo o log do serviço monitor-login:\e[0m"
    journalctl -u monitor-login.service --since "1 hour ago"
fi