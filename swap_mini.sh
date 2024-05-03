#!/bin/bash
b='\033[1m'
l='\033[4m'
y='\033[1;33m'
g='\033[0;32m'
r='\033[0;31m'
e='\033[0m'
# Проверяем, что скрипт запущен от имени root
if [[ $EUID -ne 0 ]]; then
   echo -e "${r}Этот скрипт должен быть запущен от имени ${l}root${e}${e}" 
   exit 1
fi

# Определяем размер свободного места на диске в переменную free_space
free_space=$(df -BG --output=avail / | sed '1d;s/[^0-9.]*//g')
swap_size=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
echo -e "размер свободного места на диске ${g}$free_space${e}"
echo -e "размер swap: ${g}$swap_size kB${e}"

# Проверяем, что переменная free_space определена
if [ -z "$free_space" ]; then
  echo -e "${r}${l}Ошибка${e}: переменная ${b}free_space${e} не определена${e}"
  exit 1
fi

# Проверяем, что есть достаточно свободного места на диске и swap
if [ $free_space -lt $((swap_size/1024)) ]; then
  echo -e "${r}${l}Ошибка${e}: на диске недостаточно свободного места для swap${e}"
  exit 1
fi
swapoff -a
# Запрашиваем у пользователя размер swap-файла в МБ и вносим в переменную swap_size
read -p "Введите размер swap-файла в МБ " swap_size

# Проверяем, что переменная swap_size содержит только цифры
if [[ ! $swap_size =~ ^[0-9]+$ ]]; then
   echo -e "${r}${l}Ошибка${e}: переменная swap_size должна содержать ${l}только цифры${e}${e}"
   exit 1
fi

# Создаем swap-файл
dd if=/dev/zero of=/swapfile bs=1M count=$swap_size

# Проверяем, что swap-файл создан успешно
if [ ! -f "/swapfile" ]; then
   echo -e "${r}${l}Ошибка${e}: не удалось создать swap-файл${e}"
   exit 1
fi

# Устанавливаем права доступа к swap-файлу
chmod 600 /swapfile && mkswap /swapfile

# Добавляем запись в fstab
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Включаем swap-файл
swapon /swapfile

# Проверяем, что swap-файл включен успешно
if [ -z "$(swapon -s | grep /swapfile)" ]; then
   echo -e "${R}${l}Ошибка${e}: не удалось включить swap-файл${e}"
   exit 1
fi

# Выводим сообщение об успешном завершении операции с подробностями
echo -e "${g}Swap-файл размером ${b}$swap_size МБ${e} создан успешно и включен в систему. Для проверки можно выполнить команду '${b}swapon -s${e}'.${e}"
