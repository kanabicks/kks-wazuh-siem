# 🛡️ KKS Wazuh SIEM 

**Полнофункциональная лаборатория для мониторинга безопасности, обнаружения угроз и проведения CTF соревнований.**

| |/ / |/ |/ |
| ' /| ' /| (
| < | < __ \
| . | . \ _) |
||__|____/

Security Monitoring Lab


[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)](https://www.docker.com/)  
[![Wazuh](https://img.shields.io/badge/Wazuh-4.9.0-green)](https://wazuh.com/)  
[![OpenSearch](https://img.shields.io/badge/OpenSearch-2.13.0-orange)](https://opensearch.org/)

---

## 📖 О проекте

**KKS SIEM Lab** — это готовая к развертыванию инфраструктура безопасности, построенная на базе современных open-source технологий. Проект рассчитан на:

- обучение специалистов по ИБ,
- анализ инцидентов и threat hunting,
- моделирование атак и проведение CTF.

### 🎯 Основные возможности

- ✅ Real-time мониторинг событий безопасности
- ✅ File Integrity Monitoring (FIM) критичных файлов
- ✅ Централизованный анализ логов (syslog, auth, приложения)
- ✅ Vulnerability Detection (уязвимости, пакеты)
- ✅ Compliance Monitoring (PCI DSS, GDPR, HIPAA, NIST, CIS)
- ✅ MITRE ATT&CK Mapping для алертов
- ✅ Threat Hunting и продвинутый поиск
- ✅ Готовые security dashboards

---

## 🏗️ Архитектура и технологии

### Технологический стек

| Технология           | Версия  | Назначение                                      |
|----------------------|---------|-------------------------------------------------|
| **Wazuh Manager**    | 4.9.0   | HIDS/SIEM, анализ событий, правила              |
| **Wazuh Agent**      | 4.9.0   | Endpoint мониторинг (victim-node)               |
| **OpenSearch**       | 2.13.0  | Хранение и поиск security событий               |
| **Wazuh Dashboard**  | 4.9.0   | Веб-интерфейс (на базе OpenSearch Dashboards)   |
| **Logstash**         | 8.9.0   | Pipeline: чтение alerts.json → индекс в OpenSearch |
| **Nginx**            | latest  | HTTPS reverse proxy + Basic Auth                |
| **Ubuntu**           | 22.04   | ОС для victim-node (агент)                      |

### 🔍 Компоненты

#### Wazuh SIEM

- **Manager** — принимает события от агентов, применяет decoders и rules, генерирует алерты.
- **Agent** — мониторит:
  - систему (процессы, логи, rootkits),
  - файловую систему (FIM),
  - конфигурации (SCA, CIS benchmarks).
- **SCA (Security Configuration Assessment)** — проверка соответствия CIS Benchmarks.
- **Rules Engine** — корреляция событий, присвоение уровня опасности, MITRE mapping.

#### OpenSearch (Elasticsearch fork)

- Хранение всех алертов Wazuh.
- Full-text search и агрегирования.
- Индексы вида `wazuh-alerts-YYYY.MM.DD`.
- Index templates для корректного mapping полей (keyword/date/ip).

#### eBPF (потенциальная интеграция)

Текущий стек уже готов к расширению за счет eBPF:

- мониторинг системных вызовов,
- отслеживание сетевого трафика,
- поведенческий анализ процессов.

#### Logstash

Pipeline:

Input (file: alerts.json) → Filter (date) → Output (OpenSearch + stdout)


- `file` input: `/var/ossec/logs/alerts/alerts.json`
- `json` codec
- приведение `timestamp` к `@timestamp`
- запись в индекс `wazuh-alerts-%{+YYYY.MM.dd}`

---

## 🚀 Быстрый старт

### Требования

- Docker 20.10+
- Docker Compose 2.0+
- Linux/macOS/Windows (WSL2)
- 4 GB RAM (минимум), 8+ GB желательно
- 10 GB свободного места

### Установка (вариант с setup.sh)


1. Клонируем репозиторий

git clone [https://github.com/kanabicks/wazuh-ebpf-kks.git](https://github.com/kanabicks/kks-wazuh-siem)
cd kks-wazuh-siem
2. Делаем скрипт исполняемым и запускаем

chmod +x setup.sh
./setup.sh
3. Ждём 2–3 минуты до старта контейнеров и применения index template


После установки:

- Dashboard: `https://localhost:443`
- Wazuh API: `https://localhost:55000`
- OpenSearch: `http://localhost:9200`

Логин для Dashboard: `admin`  
Пароль: тот, который задаётся при выполнении `setup.sh` или в конфиге nginx/.htpasswd.

### Ручной запуск (если без setup.sh)

1. Сгенерировать self-signed сертификаты для Nginx (`certs/nginx.crt`, `certs/nginx.key`).
2. Создать `nginx_conf/.htpasswd` с помощью `htpasswd`.
3. Скопировать `wazuh.yml.example` в `wazuh.yml` и настроить креды.
4. Запустить: docker-compose up -d


5. Применить index template для `wazuh-alerts-*` (через Dev Tools или curl).

---

## 📊 Логическая схема

┌──────────────────────────────────────────────────────┐
│ KKS SIEM  │
│ │
│ User → Nginx (443, Basic Auth) → Wazuh Dashboard │
│ ↕ │
│ OpenSearch Indexer │
│ ↑ │
│ Logstash Pipeline │
│ ↑ │
│ Wazuh Manager │
│ ↑ │
│ Wazuh Agent │
│ (Victim Node) │
└──────────────────────────────────────────────────────┘


---

## 🎯 Детекция угроз

### File Integrity Monitoring (FIM)

Мониторинг системных файлов:

- `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/ssh/*`,
- бинарники в `/usr/bin`, `/usr/sbin`,
- опционально: `/tmp`, `/home`, `/var/www`.

Примеры атак:

- добавление backdoor-пользователя в `/etc/passwd`,
- подмена бинарника `ssh`, `sudo`,
- создание исполняемых файлов в `/tmp`.

Ожидаемый алерт:

- Rule ID: ~550, группы: `syscheck`
- Level: 7–12
- MITRE: T1098 (Account Manipulation), T1499, T1204 и др.

### Log Analysis (auth, syslog)

Анализ `/var/log/auth.log`, `/var/log/syslog` на victim-node:

- brute-force SSH (многократные failed logins),
- успешные входы под root,
- sudo escalation,
- изменения пользователей и групп,
- перезапуск критичных сервисов.

Пример генерации SSH brute-force:

docker-compose exec victim-node bash -c '
for i in {1..20}; do
echo "$(date "+%b %d %H:%M:%S") victim sshd[123$i]: Failed password for invalid user hacker from 192.168.1.100 port $((20000+i)) ssh2" >> /var/log/auth.log
sleep 0.5
done
'

Ожидаемые алерты:

- группы `authentication_failed`, `sshd`
- MITRE: TA0006 (Credential Access), T1110 (Brute Force)

### Security Configuration Assessment (SCA)

Автоматический аудит по:

- CIS Ubuntu 22.04 Benchmark (логин-политики, права, auditd),
- CIS Amazon Linux 2023 (если задействован),
- парольные политики,
- настройки логирования,
- права файлов и директорий.

Результат — score и подробные алерты с remediation.

---

## 🧪 CTF-сценарии (примеры)

### 1️⃣ SSH Brute-Force

Симулируем атаку (см. выше), затем:

- Заходим в Dashboard → Threat Hunting.
- KQL фильтр: rule.groups: "authentication_failed" OR rule.description: sshd

- Анализируем chain событий, MITRE карту.

### 2️⃣ Подмена /etc/passwd

docker-compose exec victim-node bash -c
"echo 'backdoor:x:0:0:Backdoor:/root:/bin/bash' >> /etc/passwd"

Ищем:

- File Integrity Monitoring → Recent Events,
- или Discover:

syscheck.path: "/etc/passwd"

### 3️⃣ Malware Dropper в /tmp

docker-compose exec victim-node bash -c '
touch /tmp/malware_$(date +%s).elf
chmod +x /tmp/malware_*.elf
'


Ищем:

- FIM по `/tmp`,
- кастомные правила на имена файлов (`malware`, `backdoor`, `miner`).

---

## 📈 Web-интерфейс: основные разделы

- **Threat Hunting** — поиск и анализ алертов (основной инструмент).
- **File Integrity Monitoring** — все изменения файлов.
- **Configuration Assessment** — результаты CIS benchmarks.
- **MITRE ATT&CK** — отображение алертов по тактикам/техникам.
- **Vulnerability Detection** — уязвимости пакетов.
- **Discover** — сырые документы, мощный фулл-текст поиск.

Примеры KQL:


Критичные алерты за последние 24ч

rule.level >= 10 and @timestamp >= now-24h
Атаки на конкретный хост

agent.name: "12b69a55444d" and rule.level >= 7
MITRE Persistence

rule.mitre.tactic: "TA0003"
FIM изменения в /etc

syscheck.path: "/etc/*"


---

## 🔧 Кастомизация

### Локальные правила (local_rules.xml)

Пример кастомного правила:

<group name="kks_custom,syslog,sshd"> <rule id="100001" level="10"> <if_sid>5710</if_sid> <description>KKS: Multiple SSH failures detected</description> <mitre> <id>T1110</id> </mitre> </rule> </group> ```
Расширение FIM

В agent.conf (shared config):

<agent_config>
  <syscheck>
    <directories check_all="yes" realtime="yes">/tmp</directories>
    <directories check_all="yes" realtime="yes">/home</directories>
    <alert_new_files>yes</alert_new_files>
  </syscheck>
</agent_config>


🐛 Troubleshooting (кратко)

    Нет алертов в Dashboard:

        проверить wazuh-alerts-* индексы в OpenSearch,

        проверить логи Logstash и права на /var/ossec/logs/alerts/alerts.json.

    Агент не подключается:

        agent_control -l на Manager,

        логи агента на victim-node (/var/ossec/logs/ossec.log).

    Ошибки по mapping в Dashboard:

        пересоздать index template с keyword/date/ip,

        удалить старые индексы, перезапустить Logstash.




Made with ❤️ for cybersecurity education.
