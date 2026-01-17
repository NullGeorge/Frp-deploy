# FRP Installer & Manager

[English](#english) | [Русский](#russian)

---

<a name="english"></a>
## 🇬🇧 English

### 📋 Table of Contents
- [About](#about)
- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Installation Methods](#installation-methods)
- [Interactive TUI Menu](#interactive-tui-menu)
- [CLI Usage](#cli-usage)
- [Configuration Examples](#configuration-examples)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

### 📖 About

**FRP Installer** is an automated installation and management tool for [FRP (Fast Reverse Proxy)](https://github.com/fatedier/frp) with an interactive TUI menu and CLI support. This tool simplifies the deployment, configuration, and management of FRP server and client components on Linux systems.

### ✨ Features

- 🎨 **Interactive TUI Menu** - User-friendly colored interface
- 🚀 **One-line Installation** - Install via curl/wget
- 🔧 **Flexible Component Selection** - Install server, client, or both
- 🔐 **Auto Token Generation** - Automatic secure token creation
- 📊 **Real-time Status** - View service status and logs
- 🔄 **Easy Updates** - Update FRP while preserving configurations
- 🗑️ **Selective Uninstall** - Remove individual components or everything
- 📝 **Comprehensive Logging** - All operations are logged
- ⚡ **Systemd Integration** - Automatic service management
- 🎯 **CLI Mode** - Full automation support for scripts

### 📦 Requirements

- **OS**: Linux (tested on Ubuntu, Debian, CentOS, RHEL)
- **Arch**: x86_64, ARM64, ARMv7
- **Privileges**: Root access (sudo)
- **Dependencies**: `curl` or `wget`, `tar`, `openssl`, `systemd`

### 🚀 Quick Start

#### One-line Installation (Recommended)

**Install FRP Server:**
```bash
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --yes
```

**Install FRP Client:**
```bash
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --client --server-addr YOUR_SERVER_IP --token YOUR_TOKEN --yes
```

#### Manual Installation

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh -o frp-installer.sh

# Make it executable
chmod +x frp-installer.sh

# Run interactive menu
sudo ./frp-installer.sh
```

### 📥 Installation Methods

#### Method 1: One-liner via curl
```bash
# Server only
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --yes

# With custom settings
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --token mysecret --bind-port 7500 --yes

# Client only
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --client --server-addr 1.2.3.4 --token mysecret --yes

# Both server and client
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --client --yes
```

#### Method 2: One-liner via wget
```bash
wget -qO- https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --yes
```

#### Method 3: Interactive TUI Menu
```bash
sudo ./frp-installer.sh
```

### 🎨 Interactive TUI Menu

Launch the interactive menu without any arguments:

```bash
sudo ./frp-installer.sh
```

**Menu Features:**
- ✅ Install FRP components (server/client/both)
- 🔄 Manage services (start/stop/restart/enable/disable)
- 📄 View configurations
- 🔄 Update FRP to latest version
- 🗑️ Uninstall components
- 📊 View logs (systemd and installer logs)
- ℹ️ Real-time status display

### 💻 CLI Usage

```bash
frp-installer.sh [command] [options]
```

#### Commands:
- `menu` - Show interactive TUI menu (default)
- `install` - Install FRP components
- `update` - Update FRP to latest version
- `uninstall` - Uninstall FRP components

#### Options:
- `--server` - Install server component
- `--client` - Install client component
- `--token TOKEN` - Set authentication token (auto-generated if not specified for server)
- `--bind-port PORT` - Set bind port (default: 7000)
- `--quic-port PORT` - Set QUIC port (default: 7000)
- `--server-addr ADDR` - Server address (required for client)
- `--yes, -y` - Non-interactive mode (auto-confirm all prompts)
- `--dry-run` - Show what would be done without executing
- `-h, --help` - Display help message

### 📚 Configuration Examples

#### Example 1: Basic Server Installation
```bash
sudo ./frp-installer.sh install --server --yes
```
**Output:**
```
Server IP:    123.45.67.89
Bind port:    7000
Auth token:   a1b2c3d4e5f6g7h8i9j0
```

#### Example 2: Server with Custom Port
```bash
sudo ./frp-installer.sh install --server --bind-port 8000 --quic-port 8000 --token mytoken123 --yes
```

#### Example 3: Client Installation
```bash
sudo ./frp-installer.sh install --client --server-addr 123.45.67.89 --token a1b2c3d4e5f6g7h8i9j0 --yes
```

#### Example 4: Both Components
```bash
sudo ./frp-installer.sh install --server --client --yes
```

#### Example 5: Update FRP
```bash
sudo ./frp-installer.sh update
```

#### Example 6: Uninstall Everything
```bash
sudo ./frp-installer.sh uninstall --yes
```

### 🔧 Post-Installation

#### Server Configuration
Configuration file: `/etc/frp/frps.toml`
```toml
bindPort = 7000
quicBindPort = 7000

auth.method = "token"
auth.token = "your-token-here"
```

#### Client Configuration
Configuration file: `/etc/frp/frpc.toml`
```toml
serverAddr = "123.45.67.89"
serverPort = 7000
auth.method = "token"
auth.token = "your-token-here"

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000
```

#### Service Management
```bash
# Server
sudo systemctl start frps
sudo systemctl stop frps
sudo systemctl restart frps
sudo systemctl status frps
sudo systemctl enable frps   # Auto-start on boot
sudo systemctl disable frps  # Disable auto-start

# Client
sudo systemctl start frpc@frpc
sudo systemctl stop frpc@frpc
sudo systemctl status frpc@frpc
```

#### View Logs
```bash
# Server logs
sudo journalctl -u frps -f

# Client logs
sudo journalctl -u frpc@frpc -f

# Installer log
sudo tail -f /var/log/frp-installer.log
```

### 🔍 Troubleshooting

#### Check Service Status
```bash
sudo systemctl status frps
sudo systemctl status frpc@frpc
```

#### View Detailed Logs
```bash
sudo journalctl -u frps -n 100 --no-pager
```

#### Test Connection
```bash
# On server
sudo ss -tlnp | grep frps

# Test from client
telnet SERVER_IP 7000
```

#### Common Issues

**1. Port already in use**
```bash
# Check what's using the port
sudo lsof -i :7000
# or
sudo ss -tlnp | grep 7000
```

**2. Service won't start**
```bash
# Check configuration syntax
sudo /opt/frp/bin/frps -c /etc/frp/frps.toml --verify

# Check permissions
ls -la /opt/frp/bin/frps
ls -la /etc/frp/frps.toml
```

**3. Connection refused**
```bash
# Check firewall
sudo ufw status
sudo firewall-cmd --list-all

# Allow FRP port
sudo ufw allow 7000/tcp
# or for firewalld
sudo firewall-cmd --permanent --add-port=7000/tcp
sudo firewall-cmd --reload
```

### 📁 File Locations

- **Binaries**: `/opt/frp/bin/`
  - `frps` - Server binary
  - `frpc` - Client binary
- **Configurations**: `/etc/frp/`
  - `frps.toml` - Server config
  - `frpc.toml` - Client config
- **Systemd Services**: `/etc/systemd/system/`
  - `frps.service` - Server service
  - `frpc@.service` - Client service template
- **Logs**: `/var/log/frp-installer.log`

### 📄 License

This installer script is provided as-is under the MIT License.

FRP itself is licensed under Apache License 2.0 - see the [FRP repository](https://github.com/fatedier/frp) for details.

---

<a name="russian"></a>
## 🇷🇺 Русский

### 📋 Содержание
- [О проекте](#о-проекте)
- [Возможности](#возможности)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Методы установки](#методы-установки)
- [Интерактивное TUI меню](#интерактивное-tui-меню)
- [Использование CLI](#использование-cli)
- [Примеры конфигурации](#примеры-конфигурации)
- [Решение проблем](#решение-проблем)
- [Лицензия](#лицензия)

---

### 📖 О проекте

**FRP Installer** - это автоматизированный инструмент установки и управления [FRP (Fast Reverse Proxy)](https://github.com/fatedier/frp) с интерактивным TUI меню и поддержкой CLI. Инструмент упрощает развертывание, настройку и управление серверными и клиентскими компонентами FRP на Linux системах.

### ✨ Возможности

- 🎨 **Интерактивное TUI меню** - Удобный цветной интерфейс
- 🚀 **Установка одной строкой** - Установка через curl/wget
- 🔧 **Гибкий выбор компонентов** - Установка сервера, клиента или обоих
- 🔐 **Авто-генерация токена** - Автоматическое создание безопасного токена
- 📊 **Статус в реальном времени** - Просмотр статуса сервисов и логов
- 🔄 **Простое обновление** - Обновление FRP с сохранением конфигураций
- 🗑️ **Выборочное удаление** - Удаление отдельных компонентов или всего
- 📝 **Полное логирование** - Все операции записываются в лог
- ⚡ **Интеграция с systemd** - Автоматическое управление сервисами
- 🎯 **CLI режим** - Полная поддержка автоматизации для скриптов

### 📦 Требования

- **ОС**: Linux (протестировано на Ubuntu, Debian, CentOS, RHEL)
- **Архитектура**: x86_64, ARM64, ARMv7
- **Привилегии**: Root доступ (sudo)
- **Зависимости**: `curl` или `wget`, `tar`, `openssl`, `systemd`

### 🚀 Быстрый старт

#### Установка одной строкой (Рекомендуется)

**Установка FRP сервера:**
```bash
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --yes
```

**Установка FRP клиента:**
```bash
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --client --server-addr IP_ВАШЕГО_СЕРВЕРА --token ВАШ_ТОКЕН --yes
```

#### Ручная установка

```bash
# Скачать скрипт
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh -o frp-installer.sh

# Сделать исполняемым
chmod +x frp-installer.sh

# Запустить интерактивное меню
sudo ./frp-installer.sh
```

### 📥 Методы установки

#### Метод 1: Одной строкой через curl
```bash
# Только сервер
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --yes

# С пользовательскими настройками
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --token мойсекрет --bind-port 7500 --yes

# Только клиент
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --client --server-addr 1.2.3.4 --token мойсекрет --yes

# Сервер и клиент вместе
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --client --yes
```

#### Метод 2: Одной строкой через wget
```bash
wget -qO- https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | sudo bash -s -- install --server --yes
```

#### Метод 3: Интерактивное TUI меню
```bash
sudo ./frp-installer.sh
```

### 🎨 Интерактивное TUI меню

Запустите интерактивное меню без аргументов:

```bash
sudo ./frp-installer.sh
```

**Возможности меню:**
- ✅ Установка компонентов FRP (сервер/клиент/оба)
- 🔄 Управление сервисами (старт/стоп/рестарт/включить/отключить)
- 📄 Просмотр конфигураций
- 🔄 Обновление FRP до последней версии
- 🗑️ Удаление компонентов
- 📊 Просмотр логов (systemd и логи установщика)
- ℹ️ Отображение статуса в реальном времени

### 💻 Использование CLI

```bash
frp-installer.sh [команда] [опции]
```

#### Команды:
- `menu` - Показать интерактивное TUI меню (по умолчанию)
- `install` - Установить компоненты FRP
- `update` - Обновить FRP до последней версии
- `uninstall` - Удалить компоненты FRP

#### Опции:
- `--server` - Установить серверный компонент
- `--client` - Установить клиентский компонент
- `--token TOKEN` - Установить токен аутентификации (генерируется автоматически для сервера, если не указан)
- `--bind-port PORT` - Установить порт привязки (по умолчанию: 7000)
- `--quic-port PORT` - Установить QUIC порт (по умолчанию: 7000)
- `--server-addr ADDR` - Адрес сервера (обязательно для клиента)
- `--yes, -y` - Неинтерактивный режим (автоматическое подтверждение)
- `--dry-run` - Показать что будет сделано без выполнения
- `-h, --help` - Показать справку

### 📚 Примеры конфигурации

#### Пример 1: Базовая установка сервера
```bash
sudo ./frp-installer.sh install --server --yes
```
**Вывод:**
```
Server IP:    123.45.67.89
Bind port:    7000
Auth token:   a1b2c3d4e5f6g7h8i9j0
```

#### Пример 2: Сервер с пользовательским портом
```bash
sudo ./frp-installer.sh install --server --bind-port 8000 --quic-port 8000 --token мойтокен123 --yes
```

#### Пример 3: Установка клиента
```bash
sudo ./frp-installer.sh install --client --server-addr 123.45.67.89 --token a1b2c3d4e5f6g7h8i9j0 --yes
```

#### Пример 4: Оба компонента
```bash
sudo ./frp-installer.sh install --server --client --yes
```

#### Пример 5: Обновление FRP
```bash
sudo ./frp-installer.sh update
```

#### Пример 6: Полное удаление
```bash
sudo ./frp-installer.sh uninstall --yes
```

### 🔧 После установки

#### Конфигурация сервера
Файл конфигурации: `/etc/frp/frps.toml`
```toml
bindPort = 7000
quicBindPort = 7000

auth.method = "token"
auth.token = "ваш-токен-здесь"
```

#### Конфигурация клиента
Файл конфигурации: `/etc/frp/frpc.toml`
```toml
serverAddr = "123.45.67.89"
serverPort = 7000
auth.method = "token"
auth.token = "ваш-токен-здесь"

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000
```

#### Управление сервисами
```bash
# Сервер
sudo systemctl start frps
sudo systemctl stop frps
sudo systemctl restart frps
sudo systemctl status frps
sudo systemctl enable frps   # Автозапуск при загрузке
sudo systemctl disable frps  # Отключить автозапуск

# Клиент
sudo systemctl start frpc@frpc
sudo systemctl stop frpc@frpc
sudo systemctl status frpc@frpc
```

#### Просмотр логов
```bash
# Логи сервера
sudo journalctl -u frps -f

# Логи клиента
sudo journalctl -u frpc@frpc -f

# Лог установщика
sudo tail -f /var/log/frp-installer.log
```

### 🔍 Решение проблем

#### Проверка статуса сервиса
```bash
sudo systemctl status frps
sudo systemctl status frpc@frpc
```

#### Просмотр детальных логов
```bash
sudo journalctl -u frps -n 100 --no-pager
```

#### Тест соединения
```bash
# На сервере
sudo ss -tlnp | grep frps

# Тест с клиента
telnet IP_СЕРВЕРА 7000
```

#### Частые проблемы

**1. Порт уже используется**
```bash
# Проверить что использует порт
sudo lsof -i :7000
# или
sudo ss -tlnp | grep 7000
```

**2. Сервис не запускается**
```bash
# Проверить синтаксис конфигурации
sudo /opt/frp/bin/frps -c /etc/frp/frps.toml --verify

# Проверить права доступа
ls -la /opt/frp/bin/frps
ls -la /etc/frp/frps.toml
```

**3. Соединение отклонено**
```bash
# Проверить фаервол
sudo ufw status
sudo firewall-cmd --list-all

# Разрешить порт FRP
sudo ufw allow 7000/tcp
# или для firewalld
sudo firewall-cmd --permanent --add-port=7000/tcp
sudo firewall-cmd --reload
```

### 📁 Расположение файлов

- **Бинарные файлы**: `/opt/frp/bin/`
  - `frps` - Серверный бинарник
  - `frpc` - Клиентский бинарник
- **Конфигурации**: `/etc/frp/`
  - `frps.toml` - Конфигурация сервера
  - `frpc.toml` - Конфигурация клиента
- **Systemd сервисы**: `/etc/systemd/system/`
  - `frps.service` - Сервис сервера
  - `frpc@.service` - Шаблон сервиса клиента
- **Логи**: `/var/log/frp-installer.log`

### 📄 Лицензия

Данный скрипт установщика предоставляется "как есть" под лицензией MIT.

FRP распространяется под лицензией Apache License 2.0 - подробности см. в [репозитории FRP](https://github.com/fatedier/frp).

---

## 🤝 Contributing / Участие в разработке

Contributions are welcome! Feel free to submit issues and pull requests.

Мы приветствуем ваш вклад! Не стесняйтесь создавать issues и pull requests.

## ⭐ Star History

If you find this project useful, please consider giving it a star!

Если вы считаете этот проект полезным, пожалуйста, поставьте звезду!

---

**Made with ❤️ for the FRP community**