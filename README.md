# 🛡️ KKS Wazuh SIEM Lab

Полнофункциональная SIEM-платформа на базе Wazuh для мониторинга безопасности, threat hunting и CTF-соревнований. Развертывается в Docker-контейнерах за 5 минут.

## 📋 Содержание

- [Возможности](#возможности)
- [Архитектура](#архитектура)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Конфигурация](#конфигурация)
- [Использование](#использование)
- [CTF Сценарии](#ctf-сценарии)
- [Troubleshooting](#troubleshooting)
- [Лицензия](#лицензия)

## ✨ Возможности

### Security Monitoring
- **File Integrity Monitoring (FIM)** - отслеживание изменений критических файлов в `/etc`, `/bin`, `/sbin`.
- **Security Configuration Assessment (SCA)** - автоматические проверки CIS Benchmark для Ubuntu 22.04.
- **Log Analysis** - анализ syslog, auth.log, application logs с корреляцией событий.
- **Vulnerability Detection** - сканирование установленных пакетов на известные CVE.
- **Rootkit Detection** - поиск руткитов и скрытых процессов.

### Threat Detection
- Обнаружение попыток brute-force SSH/FTP.
- Детектирование malware и вредоносных скриптов.
- Мониторинг privilege escalation попыток.
- Обнаружение network reconnaissance активности.
- Алерты на подозрительные команды (sudo, whoami, netstat).

### CTF Features
- Готовые сценарии для Attack-Defense соревнований.
- Pre-configured victim node (Ubuntu 22.04) с Wazuh Agent.
- Centralized logging и real-time alerting.
- Dashboard для визуализации атак.
- MITRE ATT&CK mapping для событий.

## 🏗️ Архитектура

┌─────────────────────┐
│ Victim Node │
│ (Ubuntu 22.04) │
│ │
│ wazuh-agentd │ ← Сбор событий
│ wazuh-syscheckd │ ← FIM
│ wazuh-logcollector │ ← Логи
│ wazuh-modulesd │ ← SCA compliance
└──────┬──────────────┘
│ TCP 1514 (AES encrypted)
↓
┌─────────────────────┐
│ Wazuh Manager │
│ (Amazon Linux) │
│ │
│ wazuh-remoted │ ← Прием от агентов
│ wazuh-analysisd │ ← Rules + Decoders
│ wazuh-modulesd │ ← Vuln scanning
│ wazuh-db │ ← Agent metadata
│ wazuh-api │ ← REST API :55000
└──────┬──────────────┘
│ HTTPS
↓
┌─────────────────────┐
│ Wazuh Indexer │
│ (OpenSearch 2.13) │
│ │
│ wazuh-alerts-* │ ← Security events
│ wazuh-monitoring-* │ ← Agent health
│ wazuh-statistics │ ← Manager stats
└──────┬──────────────┘
│ HTTP :9200
↓
┌─────────────────────┐
│ Wazuh Dashboard │
│ (OpenSearch Dash) │
│ │
│ Security Analytics │
│ Compliance Reports │
│ Threat Hunting │
└──────┬──────────────┘
│ HTTP :5601
↓
┌─────────────────────┐
│ Nginx │
│ (Reverse Proxy) │
│ │
│ HTTPS :443 │
│ Basic Auth │
└─────────────────────┘

text

### Компоненты

| Сервис          | Роль                                        | Порты        |
|-----------------|---------------------------------------------|-------------|
| wazuh.manager   | SIEM engine, correlation, rules processing  | 1514,1515,55000 |
| wazuh.indexer   | Storage backend (OpenSearch)                | 9200        |
| wazuh.dashboard | Web UI для аналитики                        | 5601        |
| victim-node     | Агент-сенсор на защищаемом хосте            | -           |
| nginx           | Reverse proxy + HTTPS + Basic Auth          | 443         |
| logstash        | Alternative event pipeline (optional)       | 9600        |

## 📦 Требования

### System Requirements

- OS: Linux (Ubuntu 22.04 / Debian 11 / RHEL 8+ / Kali Linux).
- RAM: минимум 8GB (16GB рекомендуется).
- CPU: 4+ cores (8+ для больших объемов).
- Disk: 50GB свободного места (100GB+ для длительного хранения логов).
- Docker: 20.10+.
- Docker Compose: 2.0+.

### Проверка системы

free -h | grep Mem
nproc
df -h /
docker --version
docker-compose --version

text

### Установка зависимостей

Ubuntu/Debian

sudo apt update
sudo apt install -y docker.io docker-compose git apache2-utils curl
sudo usermod -aG docker $USER
RHEL/CentOS

sudo yum install -y docker docker-compose git httpd-tools curl
sudo systemctl enable --now docker

docker ps

text

## 🚀 Быстрый старт

### 1. Клонируем репозиторий

git clone https://github.com/kanabicks/kks-wazuh-siem.git
cd kks-wazuh-siem

text

### 2. Настраиваем окружение

cp .env.example .env
nano .env
htpasswd -c nginx_conf/.htpasswd admin

text

### 3. Запускаем setup-скрипт

chmod +x setup.sh
sudo ./setup.sh

text

Скрипт:
- проверит системные требования,
- сгенерирует SSL сертификаты,
- создаст случайные пароли,
- поднимет все контейнеры.

### 4. Ждём инициализации

docker-compose logs -f wazuh.manager
docker-compose ps
docker-compose logs wazuh.indexer | grep "started"

text

### 5. Доступ к интерфейсам

- Dashboard: `https://localhost:443`
- Логин: `admin`
- Пароль: см. вывод `setup.sh` или:

cat .env | grep DASHBOARD_PASSWORD

text

Wazuh API (пример):

curl -k -u wazuh-wui:wazuh-wui
-X POST "https://localhost:55000/security/user/authenticate"

text

OpenSearch API:

curl http://localhost:9200/_cat/indices?v
curl http://localhost:9200/wazuh-alerts-*/_search?pretty

text

## ⚙️ Конфигурация

### Структура проекта

kks-wazuh-siem/
├── docker-compose.yml
├── .env
├── .env.example
├── setup.sh
├── wazuh.yml.example
├── Dockerfile.dashboard
├── Dockerfile.indexer
├── sensor/
│ ├── Dockerfile
│ └── entrypoint.sh
├── nginx_conf/
│ ├── default.conf
│ └── .htpasswd.example
└── logstash/
└── pipeline/
└── wazuh.conf

text

### .env

WAZUH_VERSION=4.9.0
OPENSEARCH_VERSION=2.13.0
LOGSTASH_VERSION=8.9.0

WAZUH_ADMIN_PASSWORD=SecurePass123!
INDEXER_PASSWORD=SecurePass456!
DASHBOARD_PASSWORD=SecurePass789!

NGINX_USER=admin
NGINX_PASS=changeme

MANAGER_IP=172.18.0.5
INDEXER_IP=172.18.0.3

text

### Wazuh Manager

docker-compose exec wazuh.manager vi /var/ossec/etc/ossec.conf
docker-compose exec wazuh.manager vi /var/ossec/etc/rules/local_rules.xml
docker-compose exec wazuh.manager /var/ossec/bin/wazuh-control restart

text

### Работа с агентами

docker-compose exec wazuh.manager /var/ossec/bin/manage_agents
docker-compose exec wazuh.manager /var/ossec/bin/agent_control -l
docker-compose exec wazuh.manager /var/ossec/bin/agent_control -i 001

text

## 🎮 Использование

### Алерты

docker-compose exec wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json
docker-compose exec wazuh.manager tail -20 /var/ossec/logs/alerts/alerts.log

curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"query": {
"match": {
"rule.description": "authentication"
}
}
}'

text

### Мониторинг агентов

docker-compose exec wazuh.manager /var/ossec/bin/agent_control -l
docker-compose logs victim-node | grep "Connected to the server"
docker-compose exec wazuh.manager /var/ossec/bin/agent_control -s
docker-compose exec wazuh.manager /var/ossec/bin/wazuh-control status

text

### Аналитика

docker-compose exec wazuh.manager /var/ossec/bin/wazuh-logtest

echo "Dec 18 16:42:21 victim sshd: Failed password for root from 192.168.1.100" |
docker-compose exec -T wazuh.manager /var/ossec/bin/wazuh-logtest

curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"size": 0,
"aggs": {
"top_rules": {
"terms": {
"field": "rule.id",
"size": 10
}
}
}
}'

text

## 🎯 CTF сценарии

### 1. SSH Brute Force

docker-compose exec victim-node bash -c '
for i in {1..10}; do
logger -p auth.warning "sshd: Failed password for invalid user hacker from 192.168.1.100 port 22 ssh2"
sleep 1
done
'

sleep 15
curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"query": {
"match": {
"rule.description": "authentication"
}
}
}'

text

### 2. File Integrity Monitoring

docker-compose exec victim-node bash -c 'echo "Test change" >> /etc/passwd'
docker-compose exec victim-node /var/ossec/bin/wazuh-control restart

sleep 20
curl "http://localhost:9200/wazuh-alerts-*/_search?pretty=size=3&sort=timestamp:desc" |
grep -A 20 "Integrity checksum changed"

text

### 3. Malware Detection

docker-compose exec victim-node bash -c '
touch /tmp/malware.php
echo "<?php system(\$_GET[\"cmd\"]); ?>" > /tmp/malware.php
'

sleep 20
curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"query": {
"match": {
"data.file": "malware"
}
}
}'

text

### 4. Privilege Escalation

docker-compose exec victim-node bash -c '
logger -p auth.info "sudo: testuser : TTY=pts/0 ; PWD=/home/testuser ; USER=root ; COMMAND=/bin/bash"
'

curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"query": {
"match": {
"rule.mitre.tactic": "Privilege Escalation"
}
}
}'

text

### 5. CIS Compliance

docker-compose exec victim-node /var/ossec/bin/wazuh-control restart

curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"query": {
"match": {
"data.sca.policy": "CIS Ubuntu"
}
},
"size": 5
}'

text

## 🔧 Troubleshooting

### Permission denied в wazuh.manager

Добавь privileged: true

grep -A 5 "wazuh.manager:" docker-compose.yml

docker-compose down
docker-compose up -d wazuh.manager

text

### Connection refused к wazuh.indexer

docker-compose ps wazuh.indexer
docker-compose logs wazuh.indexer | grep "started"
curl http://localhost:9200/_cluster/health?pretty
docker-compose restart wazuh.indexer

text

### Агент не подключается

docker-compose exec victim-node ping -c 3 wazuh.manager
docker-compose exec wazuh.manager netstat -tulnp | grep -E "1514|1515"
docker-compose exec victim-node cat /var/ossec/etc/client.keys
docker-compose restart victim-node
docker-compose logs wazuh.manager | grep "Agent connected"

text

### Не пускает в Dashboard

cat .env | grep PASSWORD

docker-compose exec wazuh.indexer
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh
-cd /usr/share/wazuh-indexer/opensearch-security/
-nhnv -cacert /etc/wazuh-indexer/certs/root-ca.pem
-cert /etc/wazuh-indexer/certs/admin.pem
-key /etc/wazuh-indexer/certs/admin-key.pem

text

### Высокая нагрузка

docker stats
В docker-compose.yml:
OPENSEARCH_JAVA_OPTS: "-Xms512m -Xmx512m"

curl -X PUT "http://localhost:9200/_ilm/policy/wazuh-alerts-policy"
-H 'Content-Type: application/json' -d '
{
"policy": {
"phases": {
"delete": {
"min_age": "7d",
"actions": {
"delete": {}
}
}
}
}
}'

curl -X DELETE "http://localhost:9200/wazuh-alerts-2025.12.*"

docker-compose exec wazuh.manager vi /var/ossec/etc/ossec.conf
<frequency>86400</frequency>

text

### Nginx 502

docker-compose ps wazuh.dashboard
docker-compose logs wazuh.dashboard | tail -50
docker-compose exec nginx ping -c 3 wazuh.dashboard
docker-compose restart nginx
docker-compose exec nginx nginx -t

text

### Мало места

docker system df -v
docker system prune -af --volumes

curl -X DELETE "http://localhost:9200/wazuh-alerts-*"

docker-compose exec wazuh.manager vi /var/ossec/etc/ossec.conf
docker-compose exec wazuh.manager rm -f /var/ossec/logs/alerts/alerts.log.*

text

## 🛠️ Полезные команды

### Docker

docker-compose down
docker-compose down -v
docker-compose restart wazuh.manager
docker-compose build --no-cache
docker-compose logs -f
docker-compose logs -f wazuh.manager --tail=100
docker-compose exec wazuh.manager bash
docker-compose exec victim-node bash
docker stats

text

### Backup

docker run --rm
-v kks-wazuh-siem_wazuh-data:/data
-v $(pwd):/backup ubuntu
tar czf /backup/wazuh-backup.tar.gz /data

text

### Wazuh API

TOKEN=$(curl -k -u wazuh-wui:wazuh-wui -X POST
"https://localhost:55000/security/user/authenticate" | jq -r '.data.token')

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/agents?pretty=true"

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/agents/002?pretty=true"

curl -k -H "Authorization: Bearer $TOKEN" -X PUT
"https://localhost:55000/agents/002/restart?pretty=true"

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/manager/stats?pretty=true"

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/rules?pretty=true&limit=10"

text

### OpenSearch

curl http://localhost:9200/_cat/indices?v
curl http://localhost:9200/wazuh-alerts-*/_mapping?pretty
curl http://localhost:9200/wazuh-alerts-$(date +%Y.%m.%d)/_count?pretty

curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"size": 0,
"aggs": {
"top_agents": {
"terms": {
"field": "agent.name",
"size": 5
}
}
}
}'

curl http://localhost:9200/wazuh-alerts-*/_search?pretty
-H 'Content-Type: application/json' -d '
{
"query": {
"range": {
"rule.level": {
"gte": 10
}
}
}
}'

text

## 🤝 Contributing

Форк репозитория

git clone https://github.com/YOUR_USERNAME/kks-wazuh-siem.git
cd kks-wazuh-siem
Создание feature branch

git checkout -b feature/amazing-feature
Внесение изменений и тестирование

docker-compose down && docker-compose up -d
Commit изменений

git commit -m "Add amazing feature"
Push и PR

git push origin feature/amazing-feature

text

## 📄 Лицензия

Проект распространяется под лицензией MIT (см. LICENSE).

## 👨‍💻 Автор

KKS Security Lab  
GitHub: https://github.com/kanabicks    
