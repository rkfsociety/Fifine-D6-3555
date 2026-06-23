# Скриншоты для Space Platform

Готовые PNG в папке **`output/`** — формат **16:9**, разрешение **1280×720**.

| Файл | Назначение |
|------|------------|
| `01-settings-panel.png` | Панель настроек GIF-кнопки (RU) |
| `02-d6-keys.png` | Клавиши D6 с GIF и счётчиком |
| `03-store-hero.png` | Обложка для карточки магазина (EN) |

## Пересоздать

```powershell
cd screenshots
.\render-screenshots.ps1
```

Используется `demo.gif` и `icon.png` из пакета плагина.

## Загрузка в магазин

Прикрепите все три файла при создании карточки на https://space.key123.vip/  
Рекомендуемый порядок: `03-store-hero` → `02-d6-keys` → `01-settings-panel`.
