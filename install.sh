#!/bin/bash

# Проверка на root
if [ "$EUID" -ne 0 ]; then 
  echo "Ошибка: Запусти скрипт через sudo (sudo ./install.sh)"
  exit 1
fi

echo "--- 1. Подключение репозиториев и обновление ---"
xbps-install -Sy void-repo-nonfree
xbps-install -Syu

echo "--- 2. Установка драйверов Wi-Fi (Broadcom) ---"
# Установка заголовков ядра и DKMS (нужно для сборки драйвера wl)
xbps-install -y dkms linux-headers broadcom-wl-dkms

# Блокировка стандартных драйверов, которые ломают Wi-Fi на Lenovo
cat <<EOF > /etc/modprobe.d/broadcom-wl.conf
blacklist b43
blacklist b43legacy
blacklist ssb
blacklist bcma
blacklist brcmsmac
EOF

echo "--- 3. Установка NetworkManager ---"
xbps-install -y NetworkManager

echo "--- 4. Настройка DNS 8.8.8.8 (Google) ---"
# Удаляем старый конфиг и пишем свой
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# Делаем файл неизменяемым, чтобы DNS не "слетал"
chattr +i /etc/resolv.conf

echo "--- 5. Включение сервисов ---"
# Включаем dbus и NetworkManager через систему runit
ln -sf /etc/sv/dbus /var/service/
ln -sf /etc/sv/NetworkManager /var/service/
# Отключаем dhcpcd, чтобы он не конфликтовал с NetworkManager
rm -f /var/service/dhcpcd

echo "----------------------------------------------------"
echo "УСТАНОВКА ЗАВЕРШЕНА!"
echo "1. Введите 'reboot' для перезагрузки."
echo "2. После входа введите 'nmtui' для поиска Wi-Fi сетей."
echo "3. Если сетей нет, введите: sudo modprobe wl"
echo "----------------------------------------------------"
