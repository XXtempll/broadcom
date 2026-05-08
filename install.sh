#!/bin/bash

# Проверка прав
if [ "$EUID" -ne 0 ]; then 
  echo "Запусти от root (sudo ./install.sh)"
  exit
fi

echo "--- 1. Репозитории и Обновление ---"
xbps-install -Sy void-repo-nonfree void-repo-multilib
xbps-install -Syu

echo "--- 2. Драйверы Wi-Fi (Broadcom) и Ядро ---"
# linux-headers необходимы для сборки модуля wl через dkms
xbps-install -y dkms linux-headers broadcom-wl-dkms
# Блокируем свободные драйверы, которые мешают работе Broadcom
cat <<EOF> /etc/modprobe.d/broadcom-wl.conf
blacklist b43
blacklist b43legacy
blacklist ssb
blacklist bcma
blacklist brcmsmac
EOF

echo "--- 3. Сеть, NetworkManager и DNS 8.8.8.8 ---"
xbps-install -y NetworkManager
# Настройка статического DNS
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# Защита файла от перезаписи (атрибут immutable)
chattr +i /etc/resolv.conf

echo "--- 4. Графический стек (Intel HD 4600) ---"
xbps-install -y xorg-minimal xinit xterm mesa-dri mesa-vulkan-intel \
libgcc-32bit libstdc++-32bit libdrm-32bit MesaLib-32bit \
pipewire alsa-utils-config rtkit dbus elogind polkit

echo "--- 5. Сборка vxwm с Codeberg ---"
xbps-install -y base-devel libX11-devel libXft-devel libXinerama-devel feh dmenu
rm -rf /tmp/vxwm
git clone https://codeberg.org/wh1tepearl/vxwm.git /tmp/vxwm
cd /tmp/vxwm && make && make install
cd -

echo "--- 6. Инструменты разработки (Web) ---"
xbps-install -y vscode-bin nodejs-lts git curl

echo "--- 7. Steam и Dota 2 ---"
xbps-install -y steam

echo "--- 8. Включение сервисов (runit) ---"
# В Void мы создаем симлинки в /var/service
ln -sf /etc/sv/dbus /var/service/
ln -sf /etc/sv/NetworkManager /var/service/
ln -sf /etc/sv/elogind /var/service/
# Удаляем dhcpcd, чтобы не было конфликта с NetworkManager
rm -f /var/service/dhcpcd

echo "--- 9. Настройка автозапуска ---"
# Находим имя реального пользователя, который запустил sudo
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "exec vxwm" > "$USER_HOME/.xinitrc"
chown "$REAL_USER":"$REAL_USER" "$USER_HOME/.xinitrc"

echo "----------------------------------------------------"
echo "ГОТОВО! План действий:"
echo "1. Перезагрузись: reboot"
echo "2. После входа введи: nmtui (настрой Wi-Fi)"
echo "3. Введи: startx (запустится vxwm)"
echo "----------------------------------------------------"
