# Публикация в магазин (Space Platform)

Плагин **D6 GIF Keys** готов к подаче в каталог StreamDock / FIFINE D6.

## Пакет для загрузки

```powershell
.\package.ps1
```

Создаётся архив:

```
dist/com.rkfsociety.d6gifkeys.sdPlugin.zip
```

Внутри — папка `com.rkfsociety.d6gifkeys.sdPlugin` с `manifest.json` и всеми файлами.

## Куда подавать

| Ресурс | Ссылка |
|--------|--------|
| **Space Platform** (магазин) | https://space.key123.vip/ |
| Документация SDK | https://sdk.key123.vip/en/ |
| Поддержка | service@key123.vip |
| Discord | https://discord.gg/WvCkKRGavX |

Магазин в **fifine Control Deck** (Store → Plugins) подтягивает плагины из этой экосистемы после модерации.

## Чеклист перед отправкой

- [x] UUID с доменом автора: `com.rkfsociety.d6gifkeys.*`
- [x] `manifest.json`: Name, Version, Author, Description, URL, Icon, CategoryIcon
- [x] Иконка плагина **128×128** (`static/icon.png`)
- [x] Иконка категории **48×48** (`static/category.png`)
- [x] Локализация: `en.json`, `ru.json`, `zh_CN.json`
- [x] Лицензия MIT (`LICENSE`) и сторонние библиотеки (`THIRD_PARTY_NOTICES.md`)
- [ ] Протестировать zip: распаковать в `%APPDATA%\HotSpot\StreamDock\plugins\`, перезапустить Fifine
- [x] Скриншоты: `screenshots/output/` (см. [screenshots/README.md](screenshots/README.md))
- [ ] Заполнить описание на Space Platform (тексты ниже)

## Тексты для карточки магазина

### English (short)

**D6 GIF Keys** — show animated GIFs on FIFINE D6 and StreamDock keys. Pick a file or URL, set playback speed (25–400%), fixed FPS or native GIF timing, optional background opacity and title overlay. Also includes a counter and open-URL action.

### Русский (кратко)

**GIF-ключи D6** — анимированные GIF на кнопках FIFINE D6 и StreamDock. Файл или ссылка, скорость 25–400%, режим FPS или тайминг из GIF, прозрачность фона и подпись. Дополнительно: счётчик и открытие URL.

## Changelog для модерации (v1.6.0)

- Store-ready package: `com.rkfsociety.d6gifkeys` UUID
- Marketplace icons 128×128 / 48×48
- GIF playback speed 25–400%, FPS or native GIF timing
- MIT license

## После одобрения

Пользователи смогут установить плагин из Store в fifine Control Deck. Репозиторий остаётся для исходников и ручной установки:

```powershell
.\install.ps1 -Restart
```

## Если отклонят

Уточните причину у **service@key123.vip**. Частые замечания:

- UUID должен совпадать с доменом/брендом автора (не `com.fifine.*`)
- Иконки неверного размера
- Недостаточное описание или нестабильное поведение при загрузке URL
