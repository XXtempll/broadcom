#!/bin/bash

# Проверка на root
if [ "$EUID" -ne 0 ]; then 
  echo "Ошибка: Запусти скрипт через sudo (sudo ./install.sh)"
  exit 1
fi

# Определяем реального пользователя и его домашнюю директорию
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "--- 1. Репозитории и обновление системы ---"
xbps-install -Sy void-repo-nonfree void-repo-multilib
xbps-install -Syu

echo "--- 2. Ядро и драйверы Wi-Fi (Broadcom) ---"
xbps-install -y dkms linux-headers broadcom-wl-dkms
cat <<EOF > /etc/modprobe.d/broadcom-wl.conf
blacklist b43
blacklist b43legacy
blacklist ssb
blacklist bcma
blacklist brcmsmac
EOF

echo "--- 3. Сеть и DNS 8.8.8.8 ---"
xbps-install -y NetworkManager
rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
# Защита DNS от перезаписи
chattr +i /etc/resolv.conf

echo "--- 4. Графический стек, звук и права (xauth, xorg) ---"
xbps-install -y xorg-minimal xinit xauth xorg-server xf86-video-intel \
mesa-dri mesa-vulkan-intel libgcc-32bit libstdc++-32bit \
libdrm-32bit MesaLib-32bit pipewire alsa-utils-config rtkit dbus elogind polkit

# Установка SUID бита на Xorg (решает проблему Server X)
chmod u+s /usr/libexec/Xorg

echo "--- 5. Группы пользователя ---"
for group in video input tty audio wheel storage network; do
    groupadd -f $group
    usermod -aG $group $REAL_USER
done

echo "--- 6. Сборка vxwm (GitHub в домашнюю директорию) ---"
xbps-install -y base-devel libX11-devel libXft-devel libXinerama-devel git dmenu xterm feh

# Клонирование в ~/vxwm
cd "$USER_HOME"
rm -rf vxwm
git clone https://github.com/wh1tepearll/vxwm.git
chown -R "$REAL_USER":"$REAL_USER" vxwm

# Компиляция
cd vxwm
make && make install
cd ..

echo "--- 7. ПО для Web-разработки и Игры ---"
xbps-install -y vscode-bin nodejs-lts python3 steam

echo "--- 8. Включение сервисов ---"
ln -sf /etc/sv/dbus /var/service/
ln -sf /etc/sv/elogind /var/service/
ln -sf /etc/sv/NetworkManager /var/service/
rm -f /var/service/dhcpcd

echo "--- 9. Настройка .xinitrc ---"
echo "exec vxwm" > "$USER_HOME/.xinitrc"
chown "$REAL_USER":"$REAL_USER" "$USER_HOME/.xinitrc"

echo "----------------------------------------------------"
echo "УСТАНОВКА ЗАВЕРШЕНА!"
echo "Исходники vxwm: $USER_HOME/vxwm"
echo "1. reboot"
echo "2. startx"
echo "----------------------------------------------------"
