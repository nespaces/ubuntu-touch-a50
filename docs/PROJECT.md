# Ubuntu Touch на Samsung Galaxy A50 (SM-A505FN)

Порт Ubuntu Touch (UBports) на Galaxy A50 через **Halium 11**. Отдельный проект, не связан с HakiOS (`~/a50-port`).
Обновлено: 2026-11-12.

## Устройство
| | |
|---|---|
| Модель | SM-A505FN, кодовое имя `a50` |
| SoC / RAM | Exynos 9610, 4 GB |
| Прошивка | A505FNPUS9CVJ2 (Android 11) |
| Разделы | не A/B; system, vendor, boot, dtbo, recovery отдельными разделами |
| Загрузчик | разлочен (vboot orange), TWRP 3.7.1 |
| Ядро | Mint, 4.14.194 |
| Периферия | дисплей ea8076 AMOLED, Wi-Fi Samsung SCSC S620, звук ABOX + TFA9872 |
| adb | `/mnt/c/platform-tools/adb.exe` (серийник <serial>) |

## Структура каталога
- `kernel/mint` — исходники Mint (FreshROMs, ветка `android-14.0`, depth 1, подмодуль KernelSU)
- `kernel/halium.fragment` — опции Halium поверх `exynos9610-a50_core_defconfig`
- `kernel/out` — результат сборки (не в git)
- `tools/build-kernel.sh` — скрипт сборки с Clang 21 и системными AArch64 binutils
- `backups/device-2026-11-11` — бэкап разделов телефона + `SHA256SUMS`
- `backups/stock-firmware` — ссылка на `~/a50-port/firmware` (сток-образы Odin)
- `docs/NOTES.md` — журнал, `runs/` — логи сборок и тестов, `device/`, `halium/` — параметры и исходные компоненты Halium boot

## Бэкап (готов, проверен sha256)
boot, recovery, dtbo, vbmeta, misc, up_param, efs, sec_efs, cpefs, persistent, param, radio, keydata, keyrefuge, keystorage, steady, nad_refer, nad_fw, vendor, system — 6.3 GB. `userdata` не копировался.
Восстановление: TWRP + `adb push` образа и `dd of=/dev/block/by-name/<раздел>`.

## Сборка ядра
Команда из корня проекта: `tools/build-kernel.sh`. Логи последовательных попыток — `runs/kernel-build*.log`.
Принятые решения:
- основной конфиг `exynos9610-a50_core_defconfig` (`default` у Mint — только базис для диффа)
- `export ANDROID_MAJOR_VERSION=r` обязателен
- отключены LTO (`CONFIG_LTO_NONE=y`) и compat vDSO (нет ARM32-тулчейна)
- на хосте gcc нет, используется clang 21 + ld.lld, `HOSTCC=clang`

- Polly отключён: Clang 21 отклоняет `-polly-opt-fusion=max`. С включённым Polly эта же несовместимость приводит к отказу проверки `-fstack-protector-strong`. В изолированном `make prepare` с отключённым Polly проверка проходит, поэтому включён `CONFIG_CC_STACKPROTECTOR_STRONG=y`.
- Включены встроенный Mali и SDP/FSCRYPT_SDP, как в `exynos9610-a50_default_defconfig`. Они нужны для линковки уже включённых GPU thermal и DDAR.
- В дереве Mint есть локальные правки для Clang 21 и сборки с отдельным каталогом `O=`. Посмотреть их можно через `git -C kernel/mint diff`.
- `dtbs` создаёт базовый `exynos9610.dtb` и шесть `a50_swa_open`-оверлеев. Имена ревизий совпали со стоковым `dtbo.img`. Каждый оверлей применился к базовому DTB через `fdtoverlay`.

Последняя сборка завершилась с кодом 0 (`runs/kernel-build12.log`). ARM64 Image находится в `kernel/out/arch/arm64/boot/Image`, базовый DTB — в `kernel/out/arch/arm64/boot/dts/exynos/exynos9610.dtb`. Оверлеи находятся в `kernel/out/arch/arm64/boot/dts/samsung/`. Ядро с исправлением EMS и отключённым KernelSU загрузилось до Halium initramfs на телефоне.

## Halium boot

- Сборка: `tools/build-kernel.sh`, затем `tools/build-boot.sh`. Параметры — в `device/deviceinfo`. Для образа нужен ARM64 initramfs Halium и mkbootimg LineageOS (сохранены в `halium/`).
- Артефакт: `runs/boot.img` (46 237 712 байт), SHA-256 — `runs/boot.img.sha256`. Распаковка, сравнение ядра, initramfs и встроенного конфига, проверка заголовка и размера — `runs/boot-verify.log`.
- Заголовок Android v1, страница 2048, Android 11 / патч 2022-10, маркер SEANDROIDENFORCE. Адрес ramdisk `0x11000000` взят из стокового recovery. DT и DTBO у A50 размещаются отдельно. Образ без AVB-подписи, последний образ загружается до Halium initramfs на телефоне. Ramdisk использует стандартный поиск образов Halium, параметр `systempart=` не задан.
- Официальный `check-kernel-config` ветки `halium-9.0` (8656205f) сообщил 169 замечаний до правок и 52 после, включая повторяющиеся сообщения об отсутствующих символах. Логи — `runs/check-kernel-config-before.log` и `runs/check-kernel-config-after.log`. Включены AppArmor по умолчанию, аудит, VT, netfilter и дополнительные Binder-устройства.
- Замены старых опций: `MEMCG` и `MEMCG_SWAP`, `STRICT_KERNEL_RWX`, `NETFILTER_XT_TARGET_TPROXY`. Поддержка devpts `newinstance` встроена. A50 использует RTC S2MPU09. `/dev/mem` отключён.
- `SCHED_TUNE` и `RT_GROUP_SCHED` оставлены из-за зависимостей планировщика Mint. Smack отключён из-за конфликта с сетевыми изменениями Samsung. Для SELinux сохранено значение `CHECKREQPROT_VALUE=0`.

## Этапы
1. [x] Бэкап разделов
2. [x] Исходники ядра Mint, генерация конфига с Halium-опциями
3. [x] Сборка Image + dtb
4. [x] Проверка конфига ядра Halium (`check-kernel-config`) и применение совместимых опций
5. [x] `device/deviceinfo` и Halium `runs/boot.img`, проверенный распаковкой
6. [ ] Halium 11 (vendor из стока или сборка), rootfs UBports
7. [ ] Первая загрузка: USB-сеть (telnet/ssh 192.168.2.15)
8. [ ] Дисплей и тач (Mir + hwcomposer), Wi-Fi, звук, модем, камера, сенсоры

## Правила
- Прошивать только через TWRP, перед этим убедиться, что бэкап `boot` на месте
- EFS и модем не трогать
- Результат каждого теста дописывать в `docs/NOTES.md`
- Если TWRP не определяется по USB: sideload → `adb reboot recovery`, смена кабеля/порта
