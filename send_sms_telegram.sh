#!/bin/bash

# ID do BOT  criado no telegram ===== #
# ID do CHAT criado no telegram ===== #
BOT_TOKEN="???????"
CHAT_ID="-????????"

#A mensagem vem do Monitor_login.sh
MESSAGE=$1

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="${MESSAGE}"
