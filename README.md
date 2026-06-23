# D6 GIF Keys — плагин с анимированными GIF на кнопках Fifine D6

Плагин для **FIFINE AmpliGame D6** (и совместимого ПО StreamDock / fifine Control Deck).

**ID пакета:** `com.rkfsociety.d6gifkeys.sdPlugin` · **Версия:** 1.6.0

## Что внутри

| Действие | Описание |
|----------|----------|
| **GIF-кнопка** | Показывает анимированный GIF на клавише панели. Файл с диска или ссылка. |
| **Счётчик** | При нажатии увеличивает число на кнопке. Шаг и сброс в настройках. |
| **Открыть URL** | Открывает заданный адрес в браузере. |

## GIF-кнопка — как пользоваться

1. Перетащите действие **GIF-кнопка** на нужную клавишу D6.
2. В панели справа:
   - нажмите **Файл GIF** и выберите `.gif` на диске, **или**
   - вставьте прямую ссылку на GIF (должна открываться в браузере).
3. Настройте **Скорость (%)** — от 25% (медленнее) до 400% (быстрее), по умолчанию 100%.
4. Выберите **Тайминг**:
   - **Фиксированный FPS** — постоянная частота кадров (1–30);
   - **Как в GIF-файле** — паузы между кадрами из самого GIF, умноженные на скорость.
5. При необходимости добавьте **Подпись** поверх GIF.

### Как это работает

GIF разбирается на отдельные кадры (библиотека **omggif**) и поочерёдно отправляется на кнопку D6. **Скорость (%)** ускоряет или замедляет воспроизведение. В режиме **FPS** задаётся фиксированная частота; в режиме **Как в GIF** используются встроенные задержки кадров из файла. Подложка кнопки (`default.jpg`) рисуется с прозрачностью **Фон %** (по умолчанию 50%).

Рекомендуемый размер GIF: **до 1–2 МБ**, разрешение около **126×126** или **72×72** для плавности.

## Требования

- Windows 10/11 (или macOS)
- **fifine Control Deck** / **FIFINE D6** (StreamDock 2.9+)
- Подключённый контроллер D6

## Установка

```powershell
cd "F:\github\Fifine-D6-GifKeys"
.\install.ps1 -Restart
```

Скрипт копирует плагин в `%APPDATA%\HotSpot\StreamDock\plugins\` и удаляет старые версии (`com.fifine.*`). Флаг `-Restart` перезапускает fifine Control Deck.

Перезапустите **fifine Control Deck**. Категория в библиотеке: **GIF-ключи D6** (англ. **D6 GIF Keys**).

## Публикация в магазин

Сборка zip для [Space Platform](https://space.key123.vip/):

```powershell
.\package.ps1
```

Архив: `dist/com.rkfsociety.d6gifkeys.sdPlugin.zip`

Подробный чеклист, тексты для карточки и контакты модерации — в **[STORE.md](STORE.md)**.

## Структура проекта

```
com.rkfsociety.d6gifkeys.sdPlugin/
├── manifest.json
├── LICENSE
├── plugin/
│   ├── index.js
│   ├── gif.js
│   └── utils/
├── propertyInspector/
│   ├── gifbutton/
│   ├── counter/
│   └── openurl/
└── static/
    ├── icon.png          # 128×128, магазин
    └── category.png      # 48×48, категория
```

SDK: `F:\github\PROG\StreamDock-Plugin-SDK` · Документация: [sdk.key123.vip](https://sdk.key123.vip/en/)

## Лицензия

MIT — см. [LICENSE](LICENSE). Сторонние библиотеки: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Ссылки

- [Скачать ПО Fifine D6](https://fifinemicrophone.com/pages/download-fifine-d6-software)
- [Репозиторий](https://github.com/rkfsociety/Fifine-D6-GifKeys)
- [Space Platform (магазин плагинов)](https://space.key123.vip/)
- [StreamDock Plugin SDK](https://github.com/MiraboxSpace/StreamDock-Plugin-SDK)
