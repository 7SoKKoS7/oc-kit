# Starter prompt — iused.nl monitor setup

Paste this to your local OpenClaw agent (Telegram bot) after install completes.
The agent will scaffold the monitoring loop for you.

---

```
Привет Jarvis,

Помоги настроить мониторинг ноутбуков на iused.nl.

Что мне нужно:
- Каждые 30 минут проверять https://www.iused.nl/refurbished/macbook/
- Меня интересуют MacBook Pro M1/M2/M3 — 14" и 16" — до €1500
- Если появляется новый ноутбук — присылать уведомление в Telegram с фото, ценой, ссылкой
- Запоминать какие уже видел, чтобы не дублировать

В оc-kit есть готовый Python скрипт (setup/scripts/iused-monitor.py) — можешь
взять его за основу. Сделай:
1. Скопируй скрипт в ~/.openclaw/workspace/toolbox/scripts/
2. Создай LaunchAgent plist для запуска каждые 30 мин
3. Настрой Telegram target в env
4. Запусти один раз вручную для проверки

Покажи мне план до того как начнёшь писать код.
```

---

Adjust filter values (chip, price, screen size) to your needs.
