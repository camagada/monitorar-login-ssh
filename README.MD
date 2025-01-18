# Alerta de Login via Telegram no Ubuntu

## Etapas Passo a Passo

*Todos os arquivos necessários estão disponíveis no repositório!

### 1. Obtenha o Token do Bot do Telegram e o ID do Chat
- Crie um bot no Telegram usando o **BotFather** e obtenha o **Token**.
- Obtenha o **Chat ID** (ou **Grupo ID**) enviando uma mensagem ao bot e acessando a URL abaixo com o Token fornecido:

https://api.telegram.org/bot<SEU_BOT_TOKEN>/getUpdates

---

### 2. Crie ou copie o Script para Enviar Mensagens via Telegram
# Nesse arquivo altere as variaveis ID do BOT e ID do Chat!
  send_sms_telegram.sh

  # Torne-o executável:
  sudo chmod +x /usr/local/bin/send_sms_telegram.sh.sh

---

### 3. Monitorar Tentativas de Login no auth.log
O arquivo `/var/log/auth.log` registra todas as tentativas de login. 

### Crie ou copie o Script para Monitorar
    monitor_login.sh  

    # Torne-o executável:
    sudo chmod +x /usr/local/bin/monitor_login.sh

---

### 4. Crie ou copie o Script para montar o  Serviço
  # Crie o arquivo:
  `/etc/systemd/system/monitor-login.service`

  # Ative e inicie o serviço:
  sudo systemctl daemon-reload 
  sudo systemctl enable monitor-login.service 
  sudo systemctl start monitor-login.service

---

## Verifique se o serviço está rodando
  # Execute o comando abaixo para verificar o status do serviço:

  sudo systemctl status monitor-login.service

---

## Simule uma tentativa de login remota ou local com usuário inválido
  ssh usuario_falso@<IP_DO_SEU_SERVIDOR>
  su usuario_falso

---

## Verifique se a mensagem foi enviada via Telegram

  A mensagem deve ser algo como:

  Tentativa de login detectada no servidor <NOME_DO_SERVIDOR> em <DATA_E_HORA>

## Verifique o log de serviço
  # Se você não receber a mensagem, pode verificar o log do serviço para possíveis erros:
  sudo journalctl -u monitor-login.service

  ---

## Observação
  Testado e funcionando no ubuntu Jammy 22.04

## Não esqueça de instalar o pacote:
  apt-get install inotify-tools

  ---
