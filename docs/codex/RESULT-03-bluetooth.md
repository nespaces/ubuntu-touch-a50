# 03. Bluetooth

В `runs/halium-usbfix-boot/journal.txt` (ядро #14 с RFKILL) ошибка открытия /dev/rfkill отсутствует. К 14 секундам vendor Bluetooth service работает, bluebinder сообщает Own hci index: 1 и Bluetooth binder initialized successfully. При остановке URfkill удаляет hci0. Следовательно, RFKILL и создание виртуального контроллера работают как минимум на этапе инициализации.

Около 40 с ядро входит в OOM, среди жертв есть Lomiri. Bluebinder затем получает Cannot allocate memory при открытии сокета, выключает Bluetooth и перезапускается. При перезапуске BlueZ сообщает Failed to read version information: Failed (0x03). В `dmesg.txt` swap равен нулю. Этот прогон не позволяет заключить, что HAL или прошивка Bluetooth неисправны. Источник общего расхода памяти пока не установлен.

После USB-теста проверить `systemctl status bluebinder bluetooth`, `rfkill list`, `btmgmt info`, `bluetoothctl list`, `free -h` и `journalctl -b -u bluebinder -u bluetooth` в одной сессии. В стабильной сессии выполнить `bluetoothctl`, затем `power on`, `scan on`, `pair <MAC>` и `info <MAC>` для своих наушников или колонки в режиме сопряжения. Для подтверждения нужны обнаружение и Paired: yes. Сопряжение и работа Bluetooth-аудио не проверены. Правок Bluetooth на телефон не вносил.
