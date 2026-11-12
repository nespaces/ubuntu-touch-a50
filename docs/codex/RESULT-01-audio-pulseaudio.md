# 01. PulseAudio

В `runs/halium-usbfix-boot/journal.txt` PulseAudio выбирает `module-droid-card-30.so`, успешно читает `/vendor/etc/audio_policy_configuration.xml`, создаёт карту `droid_card.primary` и падает при открытии `primary-out → Speaker`. Последняя запись перед SIGSEGV у PID 4331 — выбор каналов front-left,front-right для 48 кГц. Точный кадр стека пока неизвестен.

В Focal установлены discover 0+2021.09 (сборка 2025-09-07), droid-30 14.2.97 (сборка 2025-10-25), droid-hidl 1.5.0 и audiosystem-passthrough. SDK 30 выбирается. Это подтверждает выбор адаптера для Android 11, совместимость реализации Samsung Audio HAL 5.0 с открытием потока ещё надо проверить.

Подготовлен пробный `overlays/01-audio/etc/pulse/touch.pa` с `helper=true`. В исходнике [module-droid-hidl](https://github.com/mer-hybris/pulseaudio-modules-droid-hidl/blob/master/src/hidl/module-droid-hidl.c) helper запускает AudioSystem passthrough после получения функций уже загруженной droid-card. Падение до этого этапа требует backtrace независимо от значения helper.

Проверка после USB-теста. В сеансе phablet сохранить оригинал touch.pa, временно подмонтировать подготовленный файл поверх /etc/pulse/touch.pa и выполнить `systemctl --user restart pulseaudio`. Проверить `journalctl --user -b -u pulseaudio`, `pactl list short sinks` и воспроизвести WAV через `paplay`. При повторном SIGSEGV снять `thread apply all bt full` в gdb для `pulseaudio --daemonize=no -vv` после остановки пользовательских pulseaudio.socket и pulseaudio.service. Проверить громкость и кнопки в Lomiri после появления рабочего sink. Откатить bind mount и перезапустить PulseAudio. Тест на устройстве ещё не выполнен.
