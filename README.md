# FRP Installer

install.sh для установки **FRP Server**.

## Установка

### Через curl (рекомендуется)
```bash
curl -fsSL https://raw.githubusercontent.com/ORG/REPO/main/install.sh | bash -s -- --yes
```

### С указанием токена и портов
```bash
curl -fsSL https://raw.githubusercontent.com/ORG/REPO/main/install.sh | bash -s -- \
  --token=MY_TOKEN \
  --bind-port=7000 \
  --yes
```

### Через bash <(curl ...)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ORG/REPO/main/install.sh) --yes
```

## Опции
- `--token` — auth token (если не указан, генерируется)
- `--bind-port` — порт сервера
- `--yes` — non-interactive
- `--dry-run` — показать действия без выполнения

## Пути
- Бинарники: `/opt/frp/bin`
- Конфиги: `/etc/frp`
- Логи: `/var/log/frp-installer.log`
- systemd: `/etc/systemd/system/frps.service`
