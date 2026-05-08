#!/bin/bash

# Проверка на root
if [ "$EUID" -ne 0 ]; then 
  echo "Запусти скрипт через sudo: sudo ./install.sh"
  exit
fi

echo "--- 1. Настройка репозиториев и обновление ---"
xbps-install -Sy void-repo-nonfree void-repo-multilib
xbps-install -Syu

echo "--- 2. Установка ядра и драйверов Wi-Fi (Lenovo G510) ---"
# linux-headers нужны для сборки драйвера Broadcom
xbps-install -y dkms linux-headers broadcom-wl-dkms

# Блокируем конфликтующие драйверы Wi-Fi
cat <<EOF > /etc/modprobe.d/broadcom-wl.conf
blacklist b43
blacklist b43legacy
blacklist ssb
blacklist bcma
blacklist brcmsmac
EOF

echo "--- 3. Установка NetworkManager и настройка DNS (8.8.8.8) ---"
xbps-install -y NetworkManager
# Отключаем стандартный dhcpcd, чтобы не конфликтовал с NetworkManager
touch /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# Делаем файл неизменяемым, чтобы система его не переписала (защита DNS)
chattr +i /etc/resolv.conf

echo "--- 4. Графика и Звук (Intel HD 4600) ---"
xbps-install -y xorg-minimal xinit xterm mesa-dri mesa-vulkan-intel \
pipewire alsa-utils-config rtkit dbus elogind polkit

echo "--- 5. Установка vxwm ---"
xbps-install -y base-devel libX11-devel libXft-devel libXinerama-devel git dmenu feh
git clone https://github.com/v-x-v/vxwm.git /tmp/vxwm
cd /tmp/vxwm && make && make install
cd -

echo "--- 6. ПО для разработки (Web) ---"
xbps-install -y vscode-bin nodejs-lts python3 python3-pip git curl

echo "--- 7. Гейминг (Steam + Dota 2) ---"
# Ставим Steam и 32-битные библиотеки для него
xbps-install -y steam libgcc-32bit libstdc++-32bit libdrm-32bit MesaLib-32bit

echo "--- 8. Включение сервисов ---"
# В Void сервисы включаются через создание симлинков
ln -sf /etc/sv/dbus /var/service/
ln -sf /etc/sv/NetworkManager /var/service/
ln -sf /etc/sv/elogind /var/service/
# Отключаем dhcpcd, если он был включен
rm -f /var/service/dhcpcd

echo "--- 9. Финальные штрихи ---"
# Настройка запуска графики для пользователя
USER_NAME=$( logname )
USER_HOME=$(eval echo "~$USER_NAME")
echo "exec vxwm" > "$USER_HOME/.xinitrc"
chown $USER_NAME:$USER_NAME "$USER_HOME/.xinitrc"

echo "----------------------------------------------------------"
echo "УСТАНОВКА ЗАВЕРШЕНА!"
echo "1. Перезагрузись: reboot"
echo "2. После перезагрузки введи: nmtui (чтобы подключить Wi-Fi)"
echo "3. Введи: startx (чтобы запустить vxwm)"
echo "----------------------------------------------------------"
