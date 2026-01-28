#!/bin/sh
set -e

# Configura o rclone
echo "[INFO] Configurando rclone..."
mkdir -p /root/.config/rclone
echo "$RCLONE_CONFIG_BASE64" | base64 -d > /root/.config/rclone/rclone.conf

# Cria o script de backup
cat <<'EOF' > /backup.sh
#!/bin/sh
set -e
echo "[INFO] Iniciando backup do PostgreSQL..."
export PGPASSWORD="$POSTGRES_PASSWORD"
DATA=$(date +%Y-%m-%d_%H-%M-%S)

echo "[INFO] Executando pg_dump..."
pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$POSTGRES_DB" > /tmp/backup.sql

echo "[INFO] Compactando backup.sql..."
tar czf /tmp/backup.tar.gz -C /tmp backup.sql

echo "[INFO] Protegendo backup com senha..."
zip -P "$BACKUP_PASSWORD" /tmp/backup-$DATA.zip /tmp/backup.tar.gz

echo "[INFO] Enviando backup para o Google Drive..."
rclone copy /tmp/backup-$DATA.zip "$BACKUP_DST"

echo "[INFO] Limpando arquivos temporários..."
rm -f /tmp/backup.sql /tmp/backup.tar.gz /tmp/backup-$DATA.zip

echo "[INFO] Backup finalizado com sucesso!"
EOF
chmod +x /backup.sh

# Agenda o cron
echo "[INFO] Agendando cron: $CRON_SCHEDULE /backup.sh"
echo "$CRON_SCHEDULE /backup.sh" > /etc/crontabs/root

# Inicia o cron
echo "[INFO] Iniciando cron..."
crond -f