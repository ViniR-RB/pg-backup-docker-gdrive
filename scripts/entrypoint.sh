#!/bin/bash
set -e


REQUIRED_VARS="RCLONE_CONFIG_BASE64 BACKUP_DST POSTGRES_HOST POSTGRES_PORT POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB BACKUP_PASSWORD CRON_SCHEDULE TZ TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID"
for VAR in $REQUIRED_VARS; do
  if [ -z "${!VAR}" ]; then
    echo "[ERRO] Variável obrigatória '$VAR' não está definida."
    exit 1
  fi
done

# Configura o rclone
echo "[INFO] Configurando rclone..."
mkdir -p /root/.config/rclone
echo "$RCLONE_CONFIG_BASE64" | base64 -d > /root/.config/rclone/rclone.conf

# Cria o script de backup
cat <<'EOF' > /backup.sh
#!/bin/sh
set -e
DATA=$(date +%Y-%m-%d_%H-%M-%S)


send_telegram_error() {
  MSG="❌ Falha no backup do PostgreSQL em $DATA. Stack trace:\n$1"
  if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
      -d chat_id="$TELEGRAM_CHAT_ID" \
      --data-urlencode text="$MSG"
  fi
}

run_with_backoff() {
  local MAX_ATTEMPTS=2
  local DELAY=2
  local ATTEMPT=1
  local ERR=""
  echo "[INFO] Executando comando com backoff: $ATTEMPT/$MAX_ATTEMPTS"
  while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if "$@"; then
      return 0
    else
      ERR=$(tail -n 20 /tmp/backup_error.log 2>/dev/null || true)
      sleep $((DELAY ** ATTEMPT))
      ATTEMPT=$((ATTEMPT + 1))
    fi
  done
  send_telegram_error "$ERR"
  exit 1
}




echo "[INFO] Iniciando backup do PostgreSQL - $DATA"
export PGPASSWORD="$POSTGRES_PASSWORD"

echo "[INFO] Executando pg_dump - $DATA"

run_with_backoff pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$POSTGRES_DB" > /tmp/backup.sql 2>/tmp/backup_error.log

echo "[INFO] Compactando backup.sql - $DATA"
tar czf /tmp/backup.tar.gz -C /tmp backup.sql

echo "[INFO] Protegendo backup com senha..."
zip -P "$BACKUP_PASSWORD" /tmp/backup-$DATA.zip /tmp/backup.tar.gz

echo "[INFO] Enviando backup para o Google Drive - $DATA"
run_with_backoff rclone copy /tmp/backup-$DATA.zip "$BACKUP_DST"

echo "[INFO] Limpando arquivos temporários - $DATA"
rm -f /tmp/backup.sql /tmp/backup.tar.gz /tmp/backup-$DATA.zip

echo "[INFO] Backup finalizado com sucesso! - $DATA"


if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  MSG="✅ Backup do PostgreSQL realizado com sucesso em $DATA"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$MSG"
fi

EOF
chmod +x /backup.sh

# Agenda o cron
echo "[INFO] Agendando cron: $CRON_SCHEDULE /backup.sh"
echo "$CRON_SCHEDULE /backup.sh" > /etc/crontabs/root

# Inicia o cron
echo "[INFO] Iniciando cron..."
crond -f