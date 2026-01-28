# PostgreSQL Backup Docker + Google Drive + Telegram

Este projeto automatiza o backup de um banco de dados PostgreSQL, compacta e protege o arquivo, envia para o Google Drive usando rclone e notifica o sucesso ou falha via Telegram.

## Como funciona

- O container executa backups agendados via cron.
- O dump do banco é compactado, protegido por senha e enviado ao Google Drive.
- Notificações de sucesso ou erro são enviadas para o Telegram.
- Todas as configurações são feitas via variáveis de ambiente em um arquivo `.env`.

## Pré-requisitos
- Docker e Docker Compose instalados
- Conta Google Drive
- Conta Telegram

## Variáveis de Ambiente

| Variável                | Descrição                                                                 | Exemplo/Link                                                                                 |
|------------------------|---------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| `CRON_SCHEDULE`        | Agendamento do backup (cron)                                              | `0 22 * * *` (todos os dias às 22h)                                                         |
| `TZ`                   | Timezone do container                                                     | `America/Sao_Paulo` [Lista de timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |
| `RCLONE_CONFIG_BASE64` | Configuração do rclone em base64                                          | Veja [Como gerar](#como-gerar-o-rclone_config_base64)                                       |
| `BACKUP_DST`           | Destino no Google Drive (remote:path)                                     | `gdrive:/backup`                                                                            |
| `POSTGRES_HOST`        | Host do banco PostgreSQL                                                  | `localhost`, `postgres`, ou endereço externo                                                |
| `POSTGRES_PORT`        | Porta do banco                                                            | `5432`                                                                                      |
| `POSTGRES_USER`        | Usuário do banco                                                          | `postgres`                                                                                  |
| `POSTGRES_PASSWORD`    | Senha do banco                                                            | `sua_senha`                                                                                 |
| `POSTGRES_DB`          | Nome do banco                                                             | `meubanco`                                                                                  |
| `BACKUP_PASSWORD`      | Senha para proteger o arquivo zip                                         | `senhaforte`                                                                                |
| `TELEGRAM_BOT_TOKEN`   | Token do bot Telegram                                                     | [Criar bot](https://core.telegram.org/bots#6-botfather)                                     |
| `TELEGRAM_CHAT_ID`     | ID do chat ou grupo Telegram                                              | [Como obter](https://stackoverflow.com/a/32572159)                                          |


## Como gerar o `RCLONE_CONFIG_BASE64`
1. Instale o [rclone](https://rclone.org/downloads/).
2. Configure um remote para o Google Drive:
   ```sh
   rclone config
   ```
   Siga o assistente e escolha Google Drive.
3. Descubra o caminho do arquivo de configuração:
   ```sh
   rclone config file
   ```
4. Converta o arquivo para base64:
   ```sh
   base64 -w 0 /caminho/para/rclone.conf
   ```
5. Cole o resultado na variável `RCLONE_CONFIG_BASE64` do seu `.env`.

## Como obter o `TELEGRAM_BOT_TOKEN` e `TELEGRAM_CHAT_ID`
- Siga o [guia oficial do Telegram](https://core.telegram.org/bots#6-botfather) para criar um bot e obter o token.
- Para obter o chat_id, envie uma mensagem para o bot e acesse:
  ```
  https://api.telegram.org/bot<SEU_TOKEN>/getUpdates
  ```
  O `chat.id` estará na resposta JSON.

## Uso
1. Configure o arquivo `.env` com suas variáveis.
2. Suba o container:
   ```sh
   docker-compose up --build -d
   ```
3. Os backups serão feitos automaticamente conforme o agendamento.

## Observações
- O backup é protegido por senha e enviado para o Google Drive.
- Notificações de sucesso ou erro são enviadas para o Telegram.
- Para restaurar, basta baixar o arquivo do Google Drive, descompactar e importar o `.sql` no PostgreSQL.

---


> Projeto desenvolvido para automação de backups seguros e notificações em tempo real.

## Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## Autor

Desenvolvido por [Vinícius](www.linkedin.com/in/vinicius-roosevelt-rodrigues-borges-876b4622a)

## Versão mais recente

Veja sempre a versão mais recente deste projeto na [página de releases](../../releases/latest).
