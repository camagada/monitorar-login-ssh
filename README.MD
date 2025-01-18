# Passo a Passo: Alerta de Login via Telegram no Ubuntu

## Etapas

### 1. Obtenha o Token do Bot do Telegram e o ID do Chat
- Crie um bot no Telegram usando o **BotFather** e obtenha o **Token**.
- Obtenha o **Chat ID** (ou **Grupo ID**) enviando uma mensagem ao bot e acessando a URL abaixo com o Token fornecido:

https://api.telegram.org/bot<SEU_BOT_TOKEN>/getUpdates


---

### 2. Crie um Script para Enviar Mensagens via Telegram
1. Crie o arquivo `/usr/local/bin/send_telegram_message.sh` com o seguinte conteúdo:
  ```bash
  #!/bin/bash

  BOT_TOKEN="SEU_BOT_TOKEN"
  CHAT_ID="SEU_CHAT_ID"
  MESSAGE="Tentativa de login detectada no servidor $(hostname) em $(date)"

  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d chat_id="${CHAT_ID}" \
      -d text="${MESSAGE}"
  ```

2. Torne-o executável:
  ```bash
  sudo chmod +x /usr/local/bin/send_telegram_message.sh
  ```

---

### 3. Monitorar Tentativas de Login no auth.log
O arquivo `/var/log/auth.log` registra todas as tentativas de login. Usaremos o **inotifywait** para monitorá-lo.

#### Criar um Script para Monitorar
1. Crie o arquivo `/usr/local/bin/monitor_login.sh` com o seguinte conteúdo:
  ```bash
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
  ```

2. Torne-o executável:
  ```bash
  sudo chmod +x /usr/local/bin/monitor_login.sh
  ```

---

### 4. Configurar o Script como Serviço
1. Crie o arquivo `/etc/systemd/system/monitor-login.service` com o seguinte conteúdo:
  ```
  [Unit]
  Description=Monitor login attempts and send alert to Telegram

  [Service]
  ExecStart=/usr/local/bin/monitor_login.sh
  Restart=always

  [Install]
  WantedBy=multi-user.target
  ```

2. Ative e inicie o serviço:
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable monitor-login.service
  sudo systemctl start monitor-login.service
  ```

---

## Conclusão
Agora, sempre que houver uma tentativa de login no sistema, uma mensagem será enviada para o seu bot no Telegram.


