#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Запусти через sudo!"
  exit 1
fi

echo "--- 1. Исправление прав и групп ---"
REAL_USER=${SUDO_USER:-$USER}
# Добавляем тебя во все нужные группы
for group in video input tty wheel audio storage; do
    groupadd -f $group
    usermod -aG $group $REAL_USER
done

echo "--- 2. Установка критических компонентов X11 ---"
# Добавляем xf86-video-fbdev как запасной драйвер
xbps-install -Sy xorg-minimal xinit xauth xorg-server xf86-video-intel \
xf86-video-fbdev mesa-dri mesa-vulkan-intel dbus elogind polkit

echo "--- 3. Настройка SUID для Xorg ---"
# Это решает проблему "Server X problem" в 90% случаев
chmod u+s /usr/libexec/Xorg

echo "--- 4. Пересборка vxwm (на случай ошибок библиотек) ---"
xbps-install -y base-devel libX11-devel libXft-devel libXinerama-devel git
rm -rf /tmp/vxwm
git clone https://codeberg.org/wh1tepearl/vxwm.git /tmp/vxwm
cd /tmp/vxwm && make && make install
cd -

echo "--- 5. Включение сервисов (КРИТИЧНО) ---"
# Без работающего dbus и elogind X-сервер может падать
ln -sf /etc/sv/dbus /var/service/
ln -sf /etc/sv/elogind /var/service/
ln -sf /etc/sv/NetworkManager /var/service/

echo "--- 6. Настройка .xinitrc ---"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
echo "exec vxwm" > "$USER_HOME/.xinitrc"
chown "$REAL_USER":"$REAL_USER" "$USER_HOME/.xinitrc"

echo "--- ГОТОВО! ПЕРЕЗАГРУЗИСЬ ОБЯЗАТЕЛЬНО (reboot) ---"
