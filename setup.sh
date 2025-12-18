#!/bin/bash
set -e

echo "🚀 Wazuh EBPF CTF Lab Setup"
echo "============================"

# 1. Проверка зависимостей
command -v docker >/dev/null 2>&1 || { echo "❌ Docker не установлен!"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose не установлен!"; exit 1; }

# 2. Создание сертификатов
echo "📜 Генерация SSL сертификатов..."
mkdir -p certs
if [ ! -f certs/nginx.key ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout certs/nginx.key \
        -out certs/nginx.crt \
        -subj "/C=RU/ST=Moscow/L=Moscow/O=CTF Lab/CN=localhost"
    echo "✅ Сертификаты созданы"
fi

# 3. Создание пароля для Nginx
echo "🔐 Создание Basic Auth..."
if [ ! -f nginx_conf/.htpasswd ]; then
    read -p "Введите пароль для admin: " -s password
    echo ""
    apt-get update && apt-get install -y apache2-utils
    htpasswd -cb nginx_conf/.htpasswd admin "$password"
    echo "✅ Пароль установлен"
fi

# 4. Копирование конфигов
echo "⚙️  Подготовка конфигов..."
if [ ! -f wazuh.yml ]; then
    cp wazuh.yml.example wazuh.yml
    echo "✅ wazuh.yml создан (измените пароль!)"
fi

# 5. Создание index template
echo "📊 Настройка OpenSearch template..."
cat > /tmp/wazuh-template.sh << 'TEMPLATE'
#!/bin/bash
sleep 30
curl -X PUT http://localhost:9200/_index_template/wazuh-alerts -H 'Content-Type: application/json' -d '{
  "index_patterns": ["wazuh-alerts-*"],
  "priority": 1,
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.mapping.total_fields.limit": 2000
    },
    "mappings": {
      "dynamic_templates": [
        {
          "strings_as_keywords": {
            "match_mapping_type": "string",
            "mapping": {
              "type": "keyword"
            }
          }
        }
      ],
      "properties": {
        "timestamp": {"type": "date"},
        "@timestamp": {"type": "date"},
        "agent.ip": {"type": "ip"}
      }
    }
  }
}'
TEMPLATE
chmod +x /tmp/wazuh-template.sh

# 6. Запуск контейнеров
echo "🐳 Запуск Docker контейнеров..."
docker-compose up -d

# 7. Ожидание готовности
echo "⏳ Ожидание запуска сервисов (60 сек)..."
sleep 60

# 8. Применение template
bash /tmp/wazuh-template.sh

# 9. Проверка статуса
echo ""
echo "✅ Установка завершена!"
echo ""
echo "📡 Доступ к сервисам:"
echo "  - Dashboard: https://localhost:443"
echo "  - Indexer: http://localhost:9200"
echo "  - Manager API: https://localhost:55000"
echo ""
echo "👤 Логин: admin"
echo "🔑 Пароль: (тот что вы указали)"
echo ""
echo "📊 Проверка агентов:"
echo "  docker-compose exec wazuh.manager /var/ossec/bin/agent_control -l"
echo ""
