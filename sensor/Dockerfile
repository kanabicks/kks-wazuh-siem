FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1. Ставим пакеты (включая rsyslog)
RUN apt-get update && \
    apt-get install -y curl gnupg lsb-release rsyslog && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
    apt-get update && \
    WAZUH_MANAGER="wazuh.manager" apt-get install -y wazuh-agent=4.9.0-1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. АВТО-НАСТРОЙКА: Добавляем syslog и auth.log в конфиг агента
RUN sed -i '/<ossec_config>/a \
  <localfile>\n\
    <log_format>syslog</log_format>\n\
    <location>/var/log/syslog</location>\n\
  </localfile>\n\
  <localfile>\n\
    <log_format>syslog</log_format>\n\
    <location>/var/log/auth.log</location>\n\
  </localfile>' /var/ossec/etc/ossec.conf

# 3. Создаем файлы логов (чтобы не было ошибок при старте)
RUN touch /var/log/syslog /var/log/auth.log && \
    chmod 666 /var/log/syslog /var/log/auth.log

# 4. Скрипт запуска: стартуем rsyslog, потом агента (ИСПРАВЛЕНО)
RUN echo '#!/bin/bash\n\
rsyslogd\n\
service wazuh-agent start\n\
tail -f /var/ossec/logs/ossec.log' > /entrypoint.sh && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
