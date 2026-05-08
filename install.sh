#!/bin/bash

# 1. Репозитории и софт
sudo xbps-install -Sy void-repo-nonfree
sudo xbps-install -Sy base-devel dkms linux-headers broadcom-wl-dkms

# 2. Блэклист конфликтующих драйверов
sudo tee /etc/modprobe.d/broadcom-wl.conf <<EOF
blacklist b43
blacklist bcma
blacklist ssb
blacklist brcmsmac
blacklist brcmfmac
EOF

# 3. Сборка драйвера (автоматический поиск версии)
VERSION=$(dkms status | grep broadcom-wl | cut -d',' -f2 | cut -d':' -f1 | tr -d ' ')
sudo dkms install broadcom-wl/$VERSION

# 4. Активация
sudo modprobe wl
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# 5. Проверка
echo "Скрипт завершен. Проверяю интернет..."
ping -c 3 google.com#!/bin/bash

echo "🚀 Начинаем полную настройку Void Linux для Lenovo G510..."

# 1. РЕПОЗИТОРИИ И ОБНОВЛЕНИЕ
echo "📦 Настройка репозиториев..."
sudo xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
sudo xbps-install -Syu

# 2. WI-FI И ДРАЙВЕРЫ (Broadcom + Intel Graphics)
echo "📶 Установка драйверов Wi-Fi и Видео..."
sudo xbps-install -y base-devel dkms linux-headers broadcom-wl-dkms \
    mesa-vulkan-intel mesa-vulkan-intel-32bit vulkan-loader intel-video-accel

# Блэклист конфликтующих драйверов
sudo tee /etc/modprobe.d/broadcom-wl.conf <<EOF
blacklist b43
blacklist bcma
blacklist ssb
blacklist brcmsmac
blacklist brcmfmac
EOF

# 3. СБОРКА VXWM (из Codeberg)
echo "🖼️ Установка графики и сборка vxwm..."
sudo xbps-install -y xorg-server xinit libX11-devel libXft-devel libXinerama-devel git alacritty
git clone https://codeberg.org/wh1tepearl/vxwm
cd vxwm && make && sudo make install && cd ..

# 4. СОФТ ДЛЯ РАЗРАБОТКИ (Python, Rust, Web)
echo "💻 Установка стека разработки..."
sudo xbps-install -y python3 python3-pip nodejs firefox neovim
# Rust (официальный инсталлер)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# 5. ИГРЫ И ЗВУК (Dota 2 + Pipewire)
echo "🎮 Подготовка к геймингу..."
sudo xbps-install -y steam pipewire wireplumber

# 6. ФИНАЛЬНАЯ НАСТРОЙКА СИСТЕМЫ
echo "⚙️ Настройка конфигов..."

# DNS Fix
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Создание .xinitrc
cat <<EOF > ~/.xinitrc
pipewire &
wireplumber &
setxkbmap -layout us,ru -option grp:alt_shift_toggle &
exec vxwm
EOF

echo "✅ ВСЁ ГОТОВО!"
echo "1. Перезагрузись: sudo reboot"
echo "2. После залогинься и пиши: startx"
echo "3. В vxwm нажми Alt+Enter для запуска терминала."
