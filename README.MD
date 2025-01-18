<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Passo a Passo: Alerta de Login via Telegram no Ubuntu</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
            background-color: #f9f9f9;
            color: #333;
        }
        h1, h2 {
            color: #007acc;
        }
        pre {
            background-color: #eee;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
        code {
            color: #d6336c;
        }
        ul {
            margin: 10px 0;
            padding-left: 20px;
        }
        .conclusion {
            background-color: #d9f7be;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Passo a Passo: Alerta de Login via Telegram no Ubuntu</h1>

    <h2>Etapas</h2>

    <h3>1. Obtenha o Token do Bot do Telegram e o ID do Chat</h3>
    <ul>
        <li>Crie um bot no Telegram usando o <strong>BotFather</strong> e obtenha o <strong>Token</strong>.</li>
        <li>Obtenha o <strong>Chat ID</strong> (ou <strong>Grupo ID</strong>) enviando uma mensagem ao bot e acessando a URL abaixo com o Token fornecido:</li>
    </ul>
    <pre>
https://api.telegram.org/bot&lt;SEU_BOT_TOKEN&gt;/getUpdates
    </pre>

    <h3>2. Crie um Script para Enviar Mensagens via Telegram</h3>
    <p>Crie o arquivo <code>/usr/local/bin/send_telegram_message.sh</code>:</p>
    <pre>
#!/bin/bash

BOT_TOKEN="SEU_BOT_TOKEN"
CHAT_ID="SEU_CHAT_ID"
MESSAGE="Tentativa de login detectada no servidor $(hostname) em $(date)"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="${MESSAGE}"
    </pre>
    <p>Torneno executável:</p>
    <pre>
sudo chmod +x /usr/local/bin/send_telegram_message.sh
    </pre>

    <h3>3. Monitorar Tentativas de Login no auth.log</h3>
    <p>O arquivo <code>/var/log/auth.log</code> registra todas as tentativas de login. Usaremos o <strong>inotifywait</strong> para monitorá-lo.</p>

    <h4>Criar um Script para Monitorar</h4>
    <p>Crie o arquivo <code>/usr/local/bin/monitor_login.sh</code>:</p>
    <pre>
#!/bin/bash

LOG_FILE="/var/log/auth.log"
TELEGRAM_SCRIPT="/usr/local/bin/send_telegram_message.sh"

inotifywait -m -e modify "${LOG_FILE}" | while read path action file; do
    # Verifica se há tentativa de login no auth.log
    if tail -n 1 "${LOG_FILE}" | grep "sshd"; then
        # Envia mensagem via Telegram
        bash "${TELEGRAM_SCRIPT}"
    fi
done
    </pre>
    <p>Torneno executável:</p>
    <pre>
sudo chmod +x /usr/local/bin/monitor_login.sh
    </pre>

    <h3>4. Configurar o Script como Serviço</h3>
    <p>Crie o arquivo <code>/etc/systemd/system/monitor-login.service</code>:</p>
    <pre>
[Unit]
Description=Monitor login attempts and send alert to Telegram

[Service]
ExecStart=/usr/local/bin/monitor_login.sh
Restart=always

[Install]
WantedBy=multi-user.target
    </pre>
    <p>Ative e inicie o serviço:</p>
    <pre>
sudo systemctl daemon-reload
sudo systemctl enable monitor-login.service
sudo systemctl start monitor-login.service
    </pre>

    <div class="conclusion">
        <h3>Conclusão</h3>
        <p>O sistema está configurado para enviar mensagens para o Telegram sempre que houver uma tentativa de login no servidor.</p>
    </div>
</body>
</html>
