# FRP Installer

install.sh для установки **FRP Server**.

## Установка

### Через curl (рекомендуется)
```bash
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | bash -s -- --yes
```

### С указанием токена и портов
```bash
curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh | bash -s -- \
  --token=MY_TOKEN \
  --bind-port=7000 
```

### Через bash <(curl ...)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/NullGeorge/Frp-deploy/refs/heads/main/install.sh) --yes
```

## Опции
- `--token` — auth token (если не указан, генерируется)
- `--bind-port` — порт сервера
- `--dry-run` — показать действия без выполнения

## Пути
- Бинарники: `/opt/frp/bin`
- Конфиги: `/etc/frp`
- Логи: `/var/log/frp-installer.log`
- systemd: `/etc/systemd/system/frps.service`
